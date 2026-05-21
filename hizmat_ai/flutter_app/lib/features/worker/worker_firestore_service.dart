import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/worker_profile.dart';

class WorkerFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createWorkerProfile(WorkerProfile profile) async {
    await _db.collection('providers').doc(profile.id).set(profile.toMap());
  }

  Future<void> updateWorkerProfile(
    String workerId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('providers').doc(workerId).update(data);
  }

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
  ) async {
    await _db.collection('providers').doc(workerId).update({
      'is_available': isAvailable,
      'last_location_update': FieldValue.serverTimestamp(),
    });
  }
}
