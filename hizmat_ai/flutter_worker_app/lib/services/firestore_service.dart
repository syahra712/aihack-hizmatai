import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/chat_message.dart';
import '../models/earning.dart';
import '../models/job.dart';
import '../models/review.dart';
import '../models/worker_profile.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Worker / Provider profile
  // ---------------------------------------------------------------------------

  Future<void> createWorkerProfile(WorkerProfile profile) async {
    await _db.collection('providers').doc(profile.id).set(profile.toMap());
  }

  Future<void> updateWorkerProfile(
    String workerId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('providers').doc(workerId).update(data);
  }

  /// Streams the worker profile doc for the given [uid].
  /// The Firestore document id may differ from the Firebase Auth uid, so we
  /// query where uid == uid and map the first result.
  Stream<WorkerProfile?> workerProfileStream(String uid) {
    return _db
        .collection('providers')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? WorkerProfile.fromFirestore(doc) : null);
  }

  Future<WorkerProfile?> getWorkerByUid(String uid) async {
    // Direct doc lookup — O(1) vs a collection scan
    final doc = await _db.collection('providers').doc(uid).get();
    if (!doc.exists) return null;
    return WorkerProfile.fromFirestore(doc);
  }

  Future<void> updateAvailability(
    String workerId,
    bool isAvailable,
    double? lat,
    double? lng,
  ) async {
    final data = <String, dynamic>{
      'is_available': isAvailable,
      'last_location_update': FieldValue.serverTimestamp(),
    };
    if (lat != null) data['lat'] = lat;
    if (lng != null) data['lng'] = lng;
    await _db.collection('providers').doc(workerId).update(data);
  }

  // ---------------------------------------------------------------------------
  // Jobs
  // ---------------------------------------------------------------------------

  Stream<List<Job>> incomingJobsStream(String workerId) {
    return _db
        .collection('bookings')
        .where('provider_id', isEqualTo: workerId)
        .where('status', isEqualTo: 'pending_worker')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Job.fromFirestore).toList());
  }

  Stream<Job?> activeJobStream(String workerId) {
    return _db
        .collection('bookings')
        .where('provider_id', isEqualTo: workerId)
        .where('status', whereIn: ['en_route', 'arrived', 'in_progress'])
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : Job.fromFirestore(snap.docs.first));
  }

  Future<List<Job>> getJobHistory(String workerId, {int limit = 20}) async {
    final snap = await _db
        .collection('bookings')
        .where('provider_id', isEqualTo: workerId)
        .where('status', whereIn: ['completed', 'cancelled'])
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(Job.fromFirestore).toList();
  }

  /// Attempts to accept a job inside a Firestore transaction.
  /// Returns `true` if accepted, `false` if the status was no longer
  /// 'pending_worker' (e.g., taken by another worker or cancelled).
  Future<bool> acceptJob(String bookingRef, String workerId) async {
    final docRef = _db.collection('bookings').doc(bookingRef);
    bool accepted = false;

    await _db.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      if (!snap.exists) return;

      final currentStatus = snap.data()?['status'] as String?;
      if (currentStatus != 'pending_worker') return;

      final now = FieldValue.serverTimestamp();
      txn.update(docRef, {
        'status': 'en_route',
        'accepted_at': now,
        'timeline': FieldValue.arrayUnion([
          {
            'step': 'accepted',
            'timestamp': DateTime.now().toIso8601String(),
            'worker_id': workerId,
          }
        ]),
      });
      accepted = true;
    });

    return accepted;
  }

  Future<void> declineJob(
    String bookingRef,
    String workerId,
    String reason,
  ) async {
    await _db.collection('bookings').doc(bookingRef).update({
      'declined_by': FieldValue.arrayUnion([
        {
          'worker_id': workerId,
          'reason': reason,
          'declined_at': DateTime.now().toIso8601String(),
        }
      ]),
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      await http.post(
        Uri.parse(
            '${AppConstants.backendBaseUrl}/worker/jobs/$bookingRef/decline'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'worker_id': workerId, 'reason': reason}),
      );
    } catch (_) {
      // Best-effort backend call; Firestore update already succeeded.
    }
  }

  Future<void> advanceJobStatus(
    String bookingRef,
    String newStatus, {
    String? timestampField,
  }) async {
    final data = <String, dynamic>{
      'status': newStatus,
      'timeline': FieldValue.arrayUnion([
        {
          'step': newStatus,
          'timestamp': DateTime.now().toIso8601String(),
        }
      ]),
    };
    if (timestampField != null) {
      data[timestampField] = FieldValue.serverTimestamp();
    }
    await _db.collection('bookings').doc(bookingRef).update(data);
  }

  Future<void> updateJobPhotos(
    String bookingRef,
    String field,
    List<String> photos,
  ) async {
    await _db.collection('bookings').doc(bookingRef).update({
      field: FieldValue.arrayUnion(photos),
    });
  }

  Future<void> addExtraWork(
    String bookingRef,
    Map<String, dynamic> extraItem,
  ) async {
    await _db.collection('bookings').doc(bookingRef).update({
      'extra_work': FieldValue.arrayUnion([extraItem]),
    });
  }

  Future<void> completeJob(
    String bookingRef,
    double actualHours,
    double finalPrice,
  ) async {
    await _db.collection('bookings').doc(bookingRef).update({
      'status': 'completed',
      'actual_hours': actualHours,
      'final_price': finalPrice,
      'completed_at': FieldValue.serverTimestamp(),
      'timeline': FieldValue.arrayUnion([
        {
          'step': 'completed',
          'timestamp': DateTime.now().toIso8601String(),
        }
      ]),
    });
  }

  // ---------------------------------------------------------------------------
  // Earnings
  // ---------------------------------------------------------------------------

  Stream<List<Earning>> earningsStream(String workerId, DateTime since) {
    return _db
        .collection('earnings')
        .where('worker_id', isEqualTo: workerId)
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Earning.fromFirestore).toList());
  }

  Future<Map<String, dynamic>> getEarningsSummary(String workerId) async {
    final now = DateTime.now();
    final todayStart =
        DateTime(now.year, now.month, now.day, 0, 0, 0);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    final monthStart = DateTime(now.year, now.month, 1);

    Future<double> sumSince(DateTime since) async {
      final snap = await _db
          .collection('earnings')
          .where('worker_id', isEqualTo: workerId)
          .where('created_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .get();
      return snap.docs.fold<double>(
        0.0,
        (sum, doc) =>
            sum + ((doc.data()['net_amount'] as num?)?.toDouble() ?? 0.0),
      );
    }

    final results = await Future.wait([
      sumSince(todayStart),
      sumSince(weekStartDay),
      sumSince(monthStart),
    ]);

    return {
      'today': results[0],
      'week': results[1],
      'month': results[2],
    };
  }

  Future<void> createEarningRecord(Earning earning) async {
    await _db.collection('earnings').add(earning.toMap());
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> notificationsStream(String workerId) {
    return _db
        .collection('notifications')
        .where('worker_id', isEqualTo: workerId)
        .orderBy('created_at', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
            .toList());
  }

  Future<void> markNotificationRead(String notifId) async {
    await _db
        .collection('notifications')
        .doc(notifId)
        .update({'read': true});
  }

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  Stream<List<ChatMessage>> chatStream(String bookingRef) {
    return _db
        .collection('bookings')
        .doc(bookingRef)
        .collection('messages')
        .orderBy('sent_at')
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  Future<void> sendMessage(String bookingRef, ChatMessage message) async {
    await _db
        .collection('bookings')
        .doc(bookingRef)
        .collection('messages')
        .add(message.toMap());
  }

  // ---------------------------------------------------------------------------
  // Reviews
  // ---------------------------------------------------------------------------

  Future<List<Review>> getReviews(String workerId) async {
    final snap = await _db
        .collection('bookings')
        .where('provider_id', isEqualTo: workerId)
        .where('customer_rating', isNotEqualTo: null)
        .orderBy('customer_rating')
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs.map(Review.fromFirestore).toList();
  }

  Future<void> replyToReview(String bookingRef, String reply) async {
    await _db.collection('bookings').doc(bookingRef).update({
      'worker_reply': reply,
      'worker_reply_at': FieldValue.serverTimestamp(),
    });
  }
}
