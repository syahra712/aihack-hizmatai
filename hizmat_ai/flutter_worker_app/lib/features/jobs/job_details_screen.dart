import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/job.dart';
import '../../providers/providers.dart';
import 'widgets/timeline_stepper.dart';

// ---------------------------------------------------------------------------
// Provider — single job detail fetched from jobHistoryProvider
// ---------------------------------------------------------------------------

final _jobDetailProvider = Provider.family<AsyncValue<Job?>, String>(
  (ref, jobRef) {
    return ref.watch(jobHistoryProvider).whenData(
          (jobs) => jobs.cast<Job?>().firstWhere(
                (j) => j?.ref == jobRef,
                orElse: () => null,
              ),
        );
  },
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class JobDetailsScreen extends ConsumerWidget {
  const JobDetailsScreen({super.key, required this.jobRef});

  final String jobRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(_jobDetailProvider(jobRef));

    return Scaffold(
      backgroundColor: WorkerColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Job Details'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: WorkerColors.accentLight,
              borderRadius: BorderRadius.circular(WorkerSizes.chipRadius),
            ),
            child: Text(
              jobRef,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: WorkerColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load job details',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: WorkerColors.error),
          ),
        ),
        data: (job) {
          if (job == null) {
            return Center(
              child: Text(
                'Job not found',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: WorkerColors.textMuted),
              ),
            );
          }
          return _JobDetailsBody(job: job);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _JobDetailsBody extends StatelessWidget {
  const _JobDetailsBody({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        WorkerSizes.pagePadding,
        16,
        WorkerSizes.pagePadding,
        40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusBanner(status: job.status),
          const SizedBox(height: WorkerSizes.sectionSpacing),
          _SectionCard(
            title: 'Service',
            child: _ServiceRow(job: job),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Customer',
            child: _CustomerRow(job: job),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Schedule',
            child: _ScheduleRow(job: job),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Price Breakdown',
            child: _PriceBreakdown(job: job),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Timeline',
            child: _ReadOnlyTimeline(job: job),
          ),
          if (job.customerRating != null) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Rating Received',
              child: _RatingSection(job: job),
            ),
          ],
          if (job.dispute != null) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Dispute',
              child: _DisputeSection(dispute: job.dispute!),
            ),
          ],
          if (job.extraWork.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Extra Work',
              child: _ExtraWorkSection(items: job.extraWork),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status banner
// ---------------------------------------------------------------------------

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final JobStatus status;

  Color get _bg {
    switch (status) {
      case JobStatus.completed:
        return WorkerColors.successLight;
      case JobStatus.cancelled:
        return WorkerColors.errorLight;
      case JobStatus.disputed:
        return WorkerColors.warningLight;
      default:
        return WorkerColors.accentLight;
    }
  }

  Color get _fg {
    switch (status) {
      case JobStatus.completed:
        return WorkerColors.success;
      case JobStatus.cancelled:
        return WorkerColors.error;
      case JobStatus.disputed:
        return WorkerColors.warning;
      default:
        return WorkerColors.accent;
    }
  }

  IconData get _icon {
    switch (status) {
      case JobStatus.completed:
        return Icons.check_circle_outline;
      case JobStatus.cancelled:
        return Icons.cancel_outlined;
      case JobStatus.disputed:
        return Icons.warning_amber_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _fg, size: 22),
          const SizedBox(width: 10),
          Text(
            status.displayLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Service row
// ---------------------------------------------------------------------------

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.job});

  final Job job;

  IconData _iconForService(String type) {
    switch (type) {
      case 'electrician':
        return Icons.electrical_services;
      case 'plumber':
        return Icons.plumbing;
      case 'ac_repair':
        return Icons.ac_unit;
      case 'cleaner':
      case 'cleaning':
      case 'home_cleaning':
        return Icons.cleaning_services;
      case 'home_tutor':
        return Icons.school;
      case 'beautician':
        return Icons.face_retouching_natural;
      case 'painter':
        return Icons.format_paint;
      case 'carpenter':
        return Icons.handyman;
      default:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: WorkerColors.accentLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _iconForService(job.serviceType),
            color: WorkerColors.accent,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.serviceLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (job.isUrgent) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: WorkerColors.errorLight,
                    borderRadius:
                        BorderRadius.circular(WorkerSizes.chipRadius),
                  ),
                  child: Text(
                    'URGENT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: WorkerColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Customer row
// ---------------------------------------------------------------------------

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.job});

  final Job job;

  String get _firstName {
    final parts = job.customerName.trim().split(' ');
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(
          icon: Icons.person_outline,
          label: 'Customer',
          value: _firstName,
        ),
        const SizedBox(height: 10),
        _DetailRow(
          icon: Icons.location_on_outlined,
          label: 'Zone',
          value: job.zone,
        ),
        const SizedBox(height: 10),
        _DetailRow(
          icon: Icons.near_me_outlined,
          label: 'Distance',
          value: '${job.distanceKm.toStringAsFixed(1)} km',
        ),
        if (job.status == JobStatus.completed &&
            job.customerAddress.isNotEmpty) ...[
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.home_outlined,
            label: 'Address',
            value: job.customerAddress,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Schedule row
// ---------------------------------------------------------------------------

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEE, d MMM yyyy').format(job.slot.toLocal());
    final timeStr = DateFormat('h:mm a').format(job.slot.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(
          icon: Icons.calendar_today_outlined,
          label: 'Date',
          value: dateStr,
        ),
        const SizedBox(height: 10),
        _DetailRow(
          icon: Icons.access_time_outlined,
          label: 'Time',
          value: timeStr,
        ),
        if (job.actualHours != null) ...[
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value:
                '${job.actualHours!.toStringAsFixed(1)} hrs',
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Price breakdown
// ---------------------------------------------------------------------------

class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final breakdown = job.priceBreakdown;
    final base = (breakdown['base'] as num?)?.toDouble() ?? 0.0;
    final urgencyFee =
        (breakdown['urgency_fee'] as num?)?.toDouble() ?? 0.0;
    final distanceFee =
        (breakdown['distance_fee'] as num?)?.toDouble() ?? 0.0;
    final extraTotal = job.extraWork.fold<double>(
      0.0,
      (sum, e) =>
          sum +
          ((e['approved'] == true)
              ? (e['amount'] as num?)?.toDouble() ?? 0.0
              : 0.0),
    );
    final total = job.finalPrice ??
        (base + urgencyFee + distanceFee + extraTotal);

    return Column(
      children: [
        _PriceRow(label: 'Base Rate', amount: base),
        if (urgencyFee > 0)
          _PriceRow(label: 'Urgency Fee', amount: urgencyFee),
        if (distanceFee > 0)
          _PriceRow(label: 'Distance Fee', amount: distanceFee),
        if (extraTotal > 0)
          _PriceRow(label: 'Extra Work', amount: extraTotal),
        const Divider(height: 20),
        _PriceRow(
          label: 'Total',
          amount: total,
          isTotal: true,
        ),
        if (job.paymentStatus.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: job.paymentStatus == 'paid'
                      ? WorkerColors.successLight
                      : WorkerColors.warningLight,
                  borderRadius:
                      BorderRadius.circular(WorkerSizes.chipRadius),
                ),
                child: Text(
                  job.paymentStatus.toUpperCase(),
                  style:
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: job.paymentStatus == 'paid'
                                ? WorkerColors.success
                                : WorkerColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  final String label;
  final double amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'PKR ${amount.toStringAsFixed(0)}',
            style: isTotal
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: WorkerColors.success,
                      fontWeight: FontWeight.w700,
                    )
                : Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: WorkerColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Read-only timeline
// ---------------------------------------------------------------------------

class _ReadOnlyTimeline extends StatelessWidget {
  const _ReadOnlyTimeline({required this.job});

  final Job job;

  List<TimelineStep> _buildSteps() {
    final idx = job.status.index;
    bool done(int i) => idx > i;
    bool current(int i) => idx == i;

    return [
      TimelineStep(
        status: 'confirmed',
        label: 'Accepted',
        done: job.acceptedAt != null,
        isCurrent: current(JobStatus.confirmed.index),
        at: job.acceptedAt,
      ),
      TimelineStep(
        status: 'en_route',
        label: 'En Route',
        done: done(JobStatus.enRoute.index),
        isCurrent: current(JobStatus.enRoute.index),
      ),
      TimelineStep(
        status: 'arrived',
        label: 'Arrived',
        done: job.arrivedAt != null,
        isCurrent: current(JobStatus.arrived.index),
        at: job.arrivedAt,
      ),
      TimelineStep(
        status: 'in_progress',
        label: 'Work Started',
        done: job.startedAt != null,
        isCurrent: current(JobStatus.inProgress.index),
        at: job.startedAt,
      ),
      TimelineStep(
        status: 'completed',
        label: 'Completed',
        done: job.completedAt != null,
        isCurrent: current(JobStatus.completed.index),
        at: job.completedAt,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TimelineStepper(
      steps: _buildSteps(),
      // onAdvance is null → read-only (no advance button rendered)
    );
  }
}

// ---------------------------------------------------------------------------
// Rating section
// ---------------------------------------------------------------------------

class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final rating = job.customerRating!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Icon(
              i < rating.round() ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 22,
            );
          })
            ..add(
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  rating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
        ),
        if (job.customerReview.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            '"${job.customerReview}"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: WorkerColors.textMuted,
                ),
          ),
        ],
        if (job.workerReply.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WorkerColors.accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.reply,
                    size: 16, color: WorkerColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.workerReply,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WorkerColors.accent,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dispute section
// ---------------------------------------------------------------------------

class _DisputeSection extends StatelessWidget {
  const _DisputeSection({required this.dispute});

  final Map<String, dynamic> dispute;

  @override
  Widget build(BuildContext context) {
    final reason = dispute['reason'] as String? ?? 'No reason provided';
    final status = dispute['status'] as String? ?? 'pending';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_outlined,
                color: WorkerColors.warning, size: 18),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: WorkerColors.warningLight,
                borderRadius:
                    BorderRadius.circular(WorkerSizes.chipRadius),
              ),
              child: Text(
                status.toUpperCase(),
                style:
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: WorkerColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          reason,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Extra work section
// ---------------------------------------------------------------------------

class _ExtraWorkSection extends StatelessWidget {
  const _ExtraWorkSection({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        final approved = item['approved'] as bool? ?? false;
        final desc = item['description'] as String? ?? '';
        final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                approved ? Icons.check_circle : Icons.pending,
                color:
                    approved ? WorkerColors.success : WorkerColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(desc,
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      'PKR ${amount.toStringAsFixed(0)} • ${approved ? 'Approved' : 'Pending'}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: approved
                                ? WorkerColors.success
                                : WorkerColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorkerSizes.cardPadding),
      decoration: BoxDecoration(
        color: WorkerColors.surface,
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        boxShadow: WorkerColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: WorkerColors.textMuted),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: WorkerColors.textMuted),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}
