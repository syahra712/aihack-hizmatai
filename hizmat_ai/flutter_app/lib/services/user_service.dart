import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/address_model.dart';
import 'firebase_service.dart';

final userServiceProvider = Provider((ref) => UserService());

final currentUserProfileProvider = FutureProvider.autoDispose<HizmatUser?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return null;
  return UserService().getUserProfile(authState.uid);
});

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<HizmatUser?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return HizmatUser.fromJson({...doc.data()!, 'uid': doc.id});
  }

  Future<void> createOrUpdateProfile(HizmatUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toJson(), SetOptions(merge: true));
  }

  Future<List<SavedAddress>> getAddresses(String uid) async {
    final snap = await _db.collection('users').doc(uid).collection('addresses').get();
    return snap.docs.map((d) => SavedAddress.fromJson({...d.data(), 'id': d.id})).toList();
  }

  Future<void> addAddress(String uid, SavedAddress address) async {
    await _db.collection('users').doc(uid).collection('addresses').doc(address.id).set(address.toJson());
  }

  Future<void> deleteAddress(String uid, String addressId) async {
    await _db.collection('users').doc(uid).collection('addresses').doc(addressId).delete();
  }
}
