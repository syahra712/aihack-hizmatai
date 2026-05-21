import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/job.dart';
import '../../providers/worker_providers.dart';
import 'widgets/availability_toggle.dart';
import 'widgets/incoming_job_overlay.dart';
import 'widgets/stats_card.dart';

class WorkerHomeScreen extends ConsumerStatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  ConsumerState<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends ConsumerState<WorkerHomeScreen> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final profileAsync = ref.watch(workerProfileProvider);
    final activeJobAsync = ref.watch(activeJobProvider);
    final todayEarningsAsync = ref.watch(todayEarningsProvider);

    // Show incoming job overlay when there are pending jobs
    ref.listen(incomingJobsProvider, (prev, next) {
      final jobs = next.valueOrNull ?? [];
      if (jobs.isNotEmpty && !_dialogShown) {
        _dialogShown = true;
        _showIncomingJobDialog(jobs.first);
      }
      if (jobs.isEmpty) _dialogShown = false;
    });

    final workerName = profileAsync.valueOrNull?.name ?? 'Worker';
    final firstNameOnly = workerName.split(' ').first;

    return Scaffold(
      backgroundColor: WorkerColors.background,
      appBar: AppBar(
        backgroundColor: WorkerColors.background,
        elevation: 0,
        titleSpacing: WorkerSizes.pagePadding,
        title: Row(
          children: [
            Text(
              'Hizmat',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: WorkerColors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'AI',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: WorkerColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                size: 26, color: WorkerColors.text),
            onPressed: () => context.go('/notifications'),
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: WorkerColors.accent,
        onRefresh: () async {
          ref.invalidate(workerProfileProvider);
          ref.invalidate(todayEarningsProvider);
          ref.invalidate(activeJobProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: WorkerSizes.pagePadding,
            vertical: 8,
          ),
          children: [
            // ── Greeting ─────────────────────────────────────────────────
            Text('Hi, $firstNameOnly!', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Ready to start earning today?',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: WorkerColors.textMuted),
            ),
            const SizedBox(height: 20),
            // ── Availability toggle ───────────────────────────────────────
            const AvailabilityToggle(),
            const SizedBox(height: 16),
            // ── Stats card ───────────────────────────────────────────────
            const StatsCard(),
            const SizedBox(height: 16),
            // ── Active job card ──────────────────────────────────────────
            activeJobAsync.when(
              data: (job) {
                if (job == null) return const SizedBox.shrink();
                return Column(
                  children: [
                    _ActiveJobCard(job: job),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // ── Recent earnings ──────────────────────────────────────────
            _SectionHeader(
              title: "Today's Earnings",
              onTap: () => context.go('/earnings'),
            ),
            const SizedBox(height: 12),
            todayEarningsAsync.when(
              data: (earnings) {
                if (earnings.isEmpty) return const _EmptyEarnings();
                final recent = earnings.take(3).toList();
                return Column(
                  children: recent.asMap().entries.map((entry) {
                    final e = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: entry.key < recent.length - 1 ? 8 : 0),
                      child: _EarningTile(
                        serviceType: e.serviceType,
                        amount: e.netAmount,
                        createdAt: e.createdAt,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: WorkerColors.accent),
                ),
              ),
              error: (_, __) => Text(
                'Could not load earnings',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showIncomingJobDialog(Job job) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => IncomingJobOverlay(
        job: job,
        onDecline: () {
          Navigator.of(context).pop();
          _dialogShown = false;
          final workerId =
              ref.read(workerProfileProvider).valueOrNull?.id ?? '';
          ref.read(firestoreServiceProvider).declineJob(
                job.ref,
                workerId,
                'worker_declined',
              );
        },
      ),
    ).then((_) => _dialogShown = false);
  }
}

// ---------------------------------------------------------------------------
// Active job card
// ---------------------------------------------------------------------------

class _ActiveJobCard extends StatelessWidget {
  final Job job;
  const _ActiveJobCard({required this.job});

  Color _statusColor(JobStatus status) {
    switch (status) {
      case JobStatus.enRoute:
        return Colors.blue;
      case JobStatus.arrived:
        return Colors.orange;
      case JobStatus.inProgress:
        return WorkerColors.success;
      default:
        return WorkerColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(WorkerSizes.cardPadding),
      decoration: BoxDecoration(
        color: WorkerColors.surface,
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        boxShadow: WorkerColors.cardShadow,
        border: Border.all(
          color: WorkerColors.accent.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: WorkerColors.accentLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  job.ref.length > 12 ? job.ref.substring(0, 12) : job.ref,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WorkerColors.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(job.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  job.status.displayLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _statusColor(job.status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.build_circle_outlined,
                  size: 18, color: WorkerColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.serviceType
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((w) => w.isNotEmpty
                          ? w[0].toUpperCase() + w.substring(1)
                          : w)
                      .join(' '),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.location_on_outlined,
                  size: 16, color: WorkerColors.textMuted),
              const SizedBox(width: 4),
              Text(job.zone, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: WorkerSizes.minTouchTarget,
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('View Active Job'),
              onPressed: () => context.go('/job/${job.ref}'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Earning tile
// ---------------------------------------------------------------------------

class _EarningTile extends StatelessWidget {
  final String serviceType;
  final double amount;
  final DateTime? createdAt;

  const _EarningTile({
    required this.serviceType,
    required this.amount,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = createdAt != null
        ? '${createdAt!.hour.toString().padLeft(2, '0')}:'
            '${createdAt!.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: WorkerColors.surface,
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        boxShadow: WorkerColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: WorkerColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_outlined,
                size: 20, color: WorkerColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceType
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((w) => w.isNotEmpty
                          ? w[0].toUpperCase() + w.substring(1)
                          : w)
                      .join(' '),
                  style: theme.textTheme.titleMedium,
                ),
                if (timeStr.isNotEmpty)
                  Text(timeStr, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            'PKR ${amount.toStringAsFixed(0)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: WorkerColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _SectionHeader({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const Spacer(),
        if (onTap != null)
          TextButton(onPressed: onTap, child: const Text('See all')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyEarnings extends StatelessWidget {
  const _EmptyEarnings();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WorkerColors.surface,
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        boxShadow: WorkerColors.cardShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 40, color: WorkerColors.textLight),
          const SizedBox(height: 12),
          Text(
            'No earnings yet today',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: WorkerColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Go online and accept jobs to start earning',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
