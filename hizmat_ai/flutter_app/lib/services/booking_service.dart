import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/booking.dart';
import '../models/provider.dart';
import 'firebase_service.dart';

final _uuid = Uuid();

final bookingServiceProvider = StateNotifierProvider<BookingNotifier, List<Booking>>((ref) {
  return BookingNotifier(ref);
});

class BookingNotifier extends StateNotifier<List<Booking>> {
  final Ref _ref;

  BookingNotifier(this._ref) : super([]) {
    _load();
  }

  CollectionReference<Map<String, dynamic>>? _collection() {
    final uid = _ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('bookings');
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookings')
        .orderBy('_createdAt', descending: true)
        .limit(20)
        .get();
    state = snap.docs.map((d) => Booking.fromJson({...d.data(), 'id': d.id})).toList();
  }

  Future<Booking> createBooking(ServiceProvider provider, String city) async {
    final uid = _ref.read(firebaseAuthProvider).currentUser?.uid;
    final booking = Booking(
      id: 'HMZ-${_uuid.v4().substring(0, 8).toUpperCase()}',
      providerName: provider.name,
      serviceType: provider.serviceType,
      city: city,
      dateTime: DateTime.now().add(const Duration(hours: 2)),
      estimatedCost: provider.priceEstimate,
      status: BookingStatus.confirmed,
      providerPhone: '+92 3${(100 + state.length) % 1000} ${1000000 + state.length * 7777}',
    );

    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bookings')
          .doc(booking.id)
          .set({...booking.toJson(), '_createdAt': FieldValue.serverTimestamp(), 'status': 'confirmed'});
    }

    state = [booking, ...state];
    return booking;
  }

  Future<void> cancelBooking(String id) async {
    _updateStatus(id, BookingStatus.cancelled, 'cancelled');
  }

  Future<void> markAsPaid(String id, {String? last4}) async {
    _updateStatus(id, BookingStatus.paid, 'paid', last4: last4);
  }

  Future<void> _updateStatus(String id, BookingStatus status, String statusStr, {String? last4}) async {
    final uid = _ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid != null) {
      final update = <String, dynamic>{'status': statusStr};
      if (last4 != null) update['paidLast4'] = last4;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bookings')
          .doc(id)
          .update(update);
    }
    state = state.map((b) => b.id == id ? b.copyWith(status: status, paidLast4: last4) : b).toList();
  }
}
