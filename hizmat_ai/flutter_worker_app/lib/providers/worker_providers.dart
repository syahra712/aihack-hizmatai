// worker_providers.dart — Riverpod providers shared across the worker app.
// All screens import from this single file to keep providers in one place.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/earning.dart';
import '../models/job.dart';
import '../models/worker_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------

final authServiceProvider = Provider<AuthService>((_) => AuthService());

final firestoreServiceProvider =
    Provider<FirestoreService>((_) => FirestoreService());

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);

// ---------------------------------------------------------------------------
// Worker profile
// ---------------------------------------------------------------------------

final workerProfileProvider = StreamProvider<WorkerProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).workerProfileStream(uid);
});

// ---------------------------------------------------------------------------
// Incoming jobs (pending_worker)
// ---------------------------------------------------------------------------

final incomingJobsProvider = StreamProvider<List<Job>>((ref) {
  final profile = ref.watch(workerProfileProvider).valueOrNull;
  if (profile == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).incomingJobsStream(profile.id);
});

// ---------------------------------------------------------------------------
// Active job
// ---------------------------------------------------------------------------

final activeJobProvider = StreamProvider<Job?>((ref) {
  final profile = ref.watch(workerProfileProvider).valueOrNull;
  if (profile == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).activeJobStream(profile.id);
});

// ---------------------------------------------------------------------------
// Today's earnings
// ---------------------------------------------------------------------------

final todayEarningsProvider = StreamProvider<List<Earning>>((ref) {
  final profile = ref.watch(workerProfileProvider).valueOrNull;
  if (profile == null) return Stream.value([]);
  final todayStart = DateTime.now();
  final startOfDay =
      DateTime(todayStart.year, todayStart.month, todayStart.day);
  return ref
      .watch(firestoreServiceProvider)
      .earningsStream(profile.id, startOfDay);
});

// ---------------------------------------------------------------------------
// Job history (FutureProvider, re-fetchable via ref.refresh)
// ---------------------------------------------------------------------------

final jobHistoryProvider = FutureProvider<List<Job>>((ref) async {
  final profile = ref.watch(workerProfileProvider).valueOrNull;
  if (profile == null) return [];
  return ref.watch(firestoreServiceProvider).getJobHistory(profile.id);
});
