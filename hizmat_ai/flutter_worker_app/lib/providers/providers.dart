/// providers.dart — Re-exports the consolidated worker providers and adds
/// screen-specific providers for the secondary screens (earnings, schedule,
/// ratings, chat, profile).
///
/// All secondary screens import ONLY from this file.
library;

export 'worker_providers.dart'
    show
        authServiceProvider,
        firestoreServiceProvider,
        authStateProvider,
        workerProfileProvider,
        incomingJobsProvider,
        activeJobProvider,
        todayEarningsProvider,
        jobHistoryProvider;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/earning.dart';
import '../models/review.dart';
import '../services/firestore_service.dart';
import 'worker_providers.dart';

// ---------------------------------------------------------------------------
// Worker ID (derived from profile stream)
// ---------------------------------------------------------------------------

final workerIdProvider = Provider<String?>((ref) {
  return ref.watch(workerProfileProvider).valueOrNull?.id;
});

// ---------------------------------------------------------------------------
// Earnings summary (today / week / month totals) — FutureProvider
// ---------------------------------------------------------------------------

final earningsSummaryProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final workerId = ref.watch(workerIdProvider);
  if (workerId == null) {
    return {'today': 0.0, 'week': 0.0, 'month': 0.0};
  }
  return ref
      .read(firestoreServiceProvider)
      .getEarningsSummary(workerId);
});

// ---------------------------------------------------------------------------
// Recent transactions (last 10 for the earnings dashboard)
// ---------------------------------------------------------------------------

final recentTransactionsProvider = StreamProvider<List<Earning>>((ref) {
  final workerId = ref.watch(workerIdProvider);
  if (workerId == null) return Stream.value([]);

  // 90-day window is wide enough for the recent-10 display
  final since = DateTime.now().subtract(const Duration(days: 90));

  return ref
      .read(firestoreServiceProvider)
      .earningsStream(workerId, since)
      .map((list) => list.take(10).toList());
});

// ---------------------------------------------------------------------------
// Transaction filter (for TransactionHistory screen)
// ---------------------------------------------------------------------------

enum TransactionFilter { thisWeek, thisMonth, allTime }

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => TransactionFilter.thisWeek);

final filteredTransactionsProvider = StreamProvider<List<Earning>>((ref) {
  final workerId = ref.watch(workerIdProvider);
  final filter = ref.watch(transactionFilterProvider);
  if (workerId == null) return Stream.value([]);

  final now = DateTime.now();
  late DateTime since;
  switch (filter) {
    case TransactionFilter.thisWeek:
      final ws = now.subtract(Duration(days: now.weekday - 1));
      since = DateTime(ws.year, ws.month, ws.day);
    case TransactionFilter.thisMonth:
      since = DateTime(now.year, now.month, 1);
    case TransactionFilter.allTime:
      since = DateTime(2020);
  }

  return ref
      .read(firestoreServiceProvider)
      .earningsStream(workerId, since);
});

// ---------------------------------------------------------------------------
// Pending payout total
// ---------------------------------------------------------------------------

final pendingPayoutProvider = FutureProvider<double>((ref) async {
  final workerId = ref.watch(workerIdProvider);
  if (workerId == null) return 0.0;

  final snap = await FirebaseFirestore.instance
      .collection('earnings')
      .where('worker_id', isEqualTo: workerId)
      .where('status', isEqualTo: 'pending')
      .get();

  return snap.docs.fold<double>(
    0.0,
    (sum, doc) =>
        sum + ((doc.data()['net_amount'] as num?)?.toDouble() ?? 0.0),
  );
});

// ---------------------------------------------------------------------------
// Weekly bookings for the calendar view
// ---------------------------------------------------------------------------

final weeklyBookingsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, DateTime>(
        (ref, weekStart) {
  final workerId = ref.watch(workerIdProvider);
  if (workerId == null) return Stream.value([]);

  final weekEnd = weekStart.add(const Duration(days: 7));

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('provider_id', isEqualTo: workerId)
      .where('slot',
          isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
      .where('slot', isLessThan: Timestamp.fromDate(weekEnd))
      .orderBy('slot')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) =>
              <String, dynamic>{'id': doc.id, ...doc.data()})
          .toList());
});

// ---------------------------------------------------------------------------
// Reviews
// ---------------------------------------------------------------------------

final reviewsProvider = FutureProvider<List<Review>>((ref) async {
  final workerId = ref.watch(workerIdProvider);
  if (workerId == null) return [];
  return ref.read(firestoreServiceProvider).getReviews(workerId);
});
