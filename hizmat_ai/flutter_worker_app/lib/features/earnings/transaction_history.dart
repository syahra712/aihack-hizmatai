import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../models/earning.dart';
import '../../providers/providers.dart';

// ---------------------------------------------------------------------------
// Transaction History Screen
// ---------------------------------------------------------------------------

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: WorkerColors.background,
      appBar: AppBar(title: const Text('Transaction History')),
      body: Column(
        children: const [
          _FilterChipsRow(),
          Expanded(child: _TransactionList()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chips
// ---------------------------------------------------------------------------

class _FilterChipsRow extends ConsumerWidget {
  const _FilterChipsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(transactionFilterProvider);

    const labels = {
      TransactionFilter.thisWeek: 'This Week',
      TransactionFilter.thisMonth: 'This Month',
      TransactionFilter.allTime: 'All Time',
    };

    return Container(
      color: WorkerColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: WorkerSizes.pagePadding,
        vertical: 12,
      ),
      child: Row(
        children: TransactionFilter.values.map((filter) {
          final selected = current == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref
                  .read(transactionFilterProvider.notifier)
                  .state = filter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                constraints: const BoxConstraints(
                    minHeight: WorkerSizes.minTouchTarget),
                decoration: BoxDecoration(
                  color: selected
                      ? WorkerColors.accent
                      : WorkerColors.accentLight,
                  borderRadius:
                      BorderRadius.circular(WorkerSizes.chipRadius),
                ),
                child: Center(
                  child: Text(
                    labels[filter]!,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: selected
                          ? Colors.white
                          : WorkerColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction list
// ---------------------------------------------------------------------------

class _TransactionList extends ConsumerWidget {
  const _TransactionList();

  IconData _iconForService(String serviceType) {
    const map = {
      'electrician': Icons.electric_bolt_outlined,
      'plumber': Icons.water_drop_outlined,
      'cleaner': Icons.cleaning_services_outlined,
      'cleaning': Icons.cleaning_services_outlined,
      'ac_repair': Icons.ac_unit_outlined,
      'home_tutor': Icons.school_outlined,
      'beautician': Icons.face_retouching_natural_outlined,
      'painter': Icons.format_paint_outlined,
      'carpenter': Icons.handyman_outlined,
    };
    return map[serviceType] ?? Icons.build_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(filteredTransactionsProvider);

    return earningsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Failed to load transactions.\nPull down to retry.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium
              ?.copyWith(color: WorkerColors.textMuted),
        ),
      ),
      data: (earnings) {
        if (earnings.isEmpty) {
          return RefreshIndicator(
            color: WorkerColors.accent,
            onRefresh: () async =>
                ref.invalidate(filteredTransactionsProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: WorkerColors.textLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: context.textTheme.headlineSmall
                            ?.copyWith(color: WorkerColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completed jobs will appear here',
                        style: context.textTheme.bodyMedium
                            ?.copyWith(color: WorkerColors.textLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: WorkerColors.accent,
          onRefresh: () async =>
              ref.invalidate(filteredTransactionsProvider),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              WorkerSizes.pagePadding,
              16,
              WorkerSizes.pagePadding,
              32,
            ),
            itemCount: earnings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final e = earnings[index];
              return _TransactionCard(
                earning: e,
                icon: _iconForService(e.serviceType),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Individual Transaction Card
// ---------------------------------------------------------------------------

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.earning, required this.icon});

  final Earning earning;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dateStr = earning.createdAt != null
        ? DateFormat('d MMM yyyy, hh:mm a').format(earning.createdAt!)
        : '—';

    return Container(
      padding: const EdgeInsets.all(WorkerSizes.cardPadding),
      decoration: BoxDecoration(
        color: WorkerColors.surface,
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        boxShadow: WorkerColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: WorkerColors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: WorkerSizes.iconSm,
                  color: WorkerColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      earning.serviceType.snakeToTitle(),
                      style: context.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      earning.bookingRef,
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: earning.status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Date
          Row(
            children: [
              const Icon(Icons.access_time_outlined,
                  size: 14, color: WorkerColors.textMuted),
              const SizedBox(width: 4),
              Text(dateStr, style: context.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          // Amount breakdown
          _AmountRow(
            label: 'Gross Amount',
            value: earning.grossAmount.formatPKR(),
            isBold: false,
          ),
          const SizedBox(height: 4),
          _AmountRow(
            label: 'Platform Fee',
            value: '- ${earning.platformFee.formatPKR()}',
            isBold: false,
            valueColor: WorkerColors.error,
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),
          _AmountRow(
            label: 'Net Earnings',
            value: earning.netAmount.formatPKR(),
            isBold: true,
            valueColor: WorkerColors.success,
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    required this.isBold,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? context.textTheme.titleSmall
              : context.textTheme.bodySmall,
        ),
        Text(
          value,
          style: (isBold
                  ? context.textTheme.titleSmall
                  : context.textTheme.bodySmall)
              ?.copyWith(
            color: valueColor,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final EarningStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case EarningStatus.cleared:
      case EarningStatus.paidOut:
        bg = WorkerColors.successLight;
        fg = WorkerColors.success;
        break;
      case EarningStatus.disputed:
        bg = WorkerColors.errorLight;
        fg = WorkerColors.error;
        break;
      case EarningStatus.pending:
        bg = WorkerColors.warningLight;
        fg = WorkerColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(WorkerSizes.chipRadius),
      ),
      child: Text(
        status.displayLabel,
        style: context.textTheme.labelSmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
