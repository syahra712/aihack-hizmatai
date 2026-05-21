import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/earning.dart';
import '../../../models/job.dart';
import '../../../providers/worker_providers.dart';

class StatsCard extends ConsumerWidget {
  const StatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final activeJob = ref.watch(activeJobProvider).valueOrNull;
    final todayEarnings = ref.watch(todayEarningsProvider).valueOrNull ?? [];
    final workerProfile = ref.watch(workerProfileProvider).valueOrNull;

    // Compute metrics
    final completedToday = todayEarnings.length;
    final totalEarnings = todayEarnings.fold<double>(
      0.0,
      (sum, e) => sum + e.netAmount,
    );
    final rating = workerProfile?.rating ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(WorkerSizes.cardPadding),
      decoration: BoxDecoration(
        color: WorkerColors.surface,
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        boxShadow: WorkerColors.cardShadow,
      ),
      child: Row(
        children: [
          // Today's Jobs
          Expanded(
            child: _StatItem(
              icon: Icons.work_outline_rounded,
              iconColor: WorkerColors.accent,
              value: activeJob != null
                  ? (completedToday + 1).toString()
                  : completedToday.toString(),
              label: "Today's Jobs",
              valueColor: WorkerColors.text,
            ),
          ),
          _Divider(),
          // Today's Earnings
          Expanded(
            child: _StatItem(
              icon: Icons.payments_outlined,
              iconColor: WorkerColors.success,
              value: 'PKR ${totalEarnings.toStringAsFixed(0)}',
              label: "Today's Earnings",
              valueColor: WorkerColors.success,
            ),
          ),
          _Divider(),
          // Rating
          Expanded(
            child: _StatItem(
              icon: Icons.star_rounded,
              iconColor: Colors.amber,
              value: rating > 0 ? rating.toStringAsFixed(1) : '--',
              label: 'Rating',
              valueColor: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color valueColor;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall,
          maxLines: 2,
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: WorkerColors.divider,
    );
  }
}
