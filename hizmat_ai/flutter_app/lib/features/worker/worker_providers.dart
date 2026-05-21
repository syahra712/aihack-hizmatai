import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/worker_profile.dart';
import 'worker_auth_service.dart';
import 'worker_firestore_service.dart';

final workerAuthServiceProvider =
    Provider<WorkerAuthService>((_) => WorkerAuthService());

final workerFirestoreServiceProvider =
    Provider<WorkerFirestoreService>((_) => WorkerFirestoreService());

final workerAuthStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(workerAuthServiceProvider).authStateChanges,
);

final workerProfileProvider = StreamProvider<WorkerProfile?>((ref) {
  final authState = ref.watch(workerAuthStateProvider);
  final uid = authState.valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(workerFirestoreServiceProvider).workerProfileStream(uid);
});
