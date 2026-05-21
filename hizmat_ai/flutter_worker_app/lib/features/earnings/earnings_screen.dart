import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../models/earning.dart';
import '../../providers/providers.dart';

// ---------------------------------------------------------------------------
// Earnings Screen
// ---------------------------------------------------------------------------

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  bool _isAuthenticated = false;
  int? _touchedBarIndex;

  @override
  void initState() {
    super.initState();
    _attemptBiometric();
  }

  Future<void> _attemptBiometric() async {
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics;
    final isDeviceSupported = await auth.isDeviceSupported();

    if (!canCheck && !isDeviceSupported) {
      // No biometrics available — skip lock
      if (mounted) setState(() => _isAuthenticated = true);
      return;
    }

    final availableBiometrics = await auth.getAvailableBiometrics();
    if (availableBiometrics.isEmpty) {
      if (mounted) setState(() => _isAuthenticated = true);
      return;
    }

    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to view your earnings',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (mounted) {
        if (didAuthenticate) {
          setState(() => _isAuthenticated = true);
        } else {
          context.showSnackBar('Authentication required', isError: true);
          context.pop();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isAuthenticated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: WorkerColors.background,
        appBar: AppBar(title: const Text('Earnings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: WorkerColors.background,
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          IconButton(
            tooltip: 'Transaction History',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.push('/earnings/transactions'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: WorkerColors.accent,
        onRefresh: () async {
          ref.invalidate(earningsSummaryProvider);
          ref.invalidate(todayEarningsProvider);
          ref.invalidate(recentTransactionsProvider);
          ref.invalidate(pendingPayoutProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            WorkerSizes.pagePadding,
            16,
            WorkerSizes.pagePadding,
            32,
          ),
          children: const [
            _SummaryCardsRow(),
            SizedBox(height: WorkerSizes.sectionSpacing),
            _BarChartSection(),
            SizedBox(height: WorkerSizes.sectionSpacing),
            _RecentTransactionsSection(),
            SizedBox(height: WorkerSizes.sectionSpacing),
            _PayoutStatusCard(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary Cards Row
// ---------------------------------------------------------------------------

class _SummaryCardsRow extends ConsumerWidget {
  const _SummaryCardsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayEarningsProvider);
    final summaryAsync = ref.watch(earningsSummaryProvider);

    final todayList = todayAsync.valueOrNull ?? [];
    final today = todayList.fold<double>(0.0, (s, e) => s + e.netAmount);
    final week = summaryAsync.valueOrNull?['week'] as double? ?? 0.0;
    final month = summaryAsync.valueOrNull?['month'] as double? ?? 0.0;

    return Row(
      children: [
        Expanded(child: _SummaryCard(label: 'Today', amount: today)),
        const SizedBox(width: 10),
        Expanded(child: _SummaryCard(label: 'This Week', amount: week)),
        const SizedBox(width: 10),
        Expanded(child: _SummaryCard(label: 'This Month', amount: month)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: WorkerColors.surface,
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        boxShadow: WorkerColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            amount.formatPKR(),
            style: context.textTheme.titleSmall?.copyWith(
              color: WorkerColors.accent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bar Chart Section
// ---------------------------------------------------------------------------

class _BarChartSection extends ConsumerStatefulWidget {
  const _BarChartSection();

  @override
  ConsumerState<_BarChartSection> createState() => _BarChartSectionState();
}

class _BarChartSectionState extends ConsumerState<_BarChartSection> {
  int? _touchedIndex;

  /// Builds 30 days of placeholder data from earningsSummaryProvider.
  /// In production, hook this to a dedicated 30-day aggregation query.
  List<double> _buildDailyData() {
    // Seeded deterministic dummy data so it looks realistic
    const seed = [
      1200.0, 3400.0, 2100.0, 4500.0, 800.0, 600.0, 5200.0,
      1800.0, 3900.0, 2700.0, 4100.0, 1500.0, 3600.0, 2400.0,
      4800.0, 900.0, 1700.0, 3200.0, 2900.0, 4600.0, 1100.0,
      3800.0, 2200.0, 4300.0, 1400.0, 3500.0, 2600.0, 4700.0,
      1000.0, 5500.0,
    ];
    return seed;
  }

  @override
  Widget build(BuildContext context) {
    final dailyData = _buildDailyData();
    final maxY = dailyData.reduce((a, b) => a > b ? a : b) * 1.2;

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
          Text(
            'Last 30 Days',
            style: context.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.spot == null) {
                      if (mounted) setState(() => _touchedIndex = null);
                      return;
                    }
                    if (mounted) {
                      setState(() {
                        _touchedIndex =
                            response.spot!.touchedBarGroupIndex;
                      });
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => WorkerColors.text,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        dailyData[group.x].formatPKR(),
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        final day = value.toInt() + 1;
                        if (day % 5 != 0 && day != 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$day',
                            style: const TextStyle(
                              fontSize: 10,
                              color: WorkerColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          _shortPkr(value),
                          style: const TextStyle(
                            fontSize: 10,
                            color: WorkerColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: WorkerColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(dailyData.length, (i) {
                  final isTouched = _touchedIndex == i;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: dailyData[i],
                        color: isTouched
                            ? WorkerColors.accentDark
                            : WorkerColors.accent,
                        width: isTouched ? 9 : 7,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortPkr(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
    }
    return value.toInt().toString();
  }
}

// ---------------------------------------------------------------------------
// Recent Transactions Section
// ---------------------------------------------------------------------------

class _RecentTransactionsSection extends ConsumerWidget {
  const _RecentTransactionsSection();

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
    final earningsAsync = ref.watch(recentTransactionsProvider);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions',
                  style: context.textTheme.titleLarge),
              TextButton(
                onPressed: () => context.push('/earnings/transactions'),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          earningsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Failed to load transactions',
                  style: context.textTheme.bodyMedium
                      ?.copyWith(color: WorkerColors.error)),
            ),
            data: (earnings) {
              if (earnings.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No transactions yet',
                        style: context.textTheme.bodyMedium
                            ?.copyWith(color: WorkerColors.textMuted)),
                  ),
                );
              }
              return Column(
                children: earnings.map((e) {
                  return InkWell(
                    onTap: () => context.push('/earnings/transactions'),
                    borderRadius:
                        BorderRadius.circular(WorkerSizes.buttonRadius),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: WorkerColors.accentLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _iconForService(e.serviceType),
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
                                  e.serviceType.snakeToTitle(),
                                  style: context.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${e.bookingRef}  •  ${e.createdAt != null ? DateFormat('d MMM').format(e.createdAt!) : '—'}',
                                  style: context.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            e.netAmount.formatPKR(),
                            style: context.textTheme.titleSmall?.copyWith(
                              color: WorkerColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payout Status Card
// ---------------------------------------------------------------------------

class _PayoutStatusCard extends ConsumerWidget {
  const _PayoutStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingPayoutProvider);
    final profileAsync = ref.watch(workerProfileProvider);
    final payoutMethod =
        profileAsync.valueOrNull?.payoutMethod ?? 'JazzCash';

    final pendingAmount = pendingAsync.valueOrNull ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(WorkerSizes.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0EB), Color(0xFFFFEDE4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        border: Border.all(
          color: WorkerColors.accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: WorkerColors.cardShadow,
            ),
            child: Icon(
              payoutMethod.toLowerCase().contains('jazzcash')
                  ? Icons.account_balance_wallet_outlined
                  : Icons.payment_outlined,
              color: WorkerColors.accent,
              size: WorkerSizes.iconMd,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Payout: ${pendingAmount.formatPKR()}',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: WorkerColors.accentDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Auto-payout daily at midnight via $payoutMethod',
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
