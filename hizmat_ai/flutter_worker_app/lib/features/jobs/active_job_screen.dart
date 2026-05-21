import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/job.dart';
import '../../providers/worker_providers.dart';
import 'widgets/extra_work_sheet.dart';
import 'widgets/photo_capture.dart';
import 'widgets/timeline_stepper.dart';

// ---------------------------------------------------------------------------
// Provider: stream a single booking doc by ref
// ---------------------------------------------------------------------------

final _jobStreamProvider =
    StreamProvider.family<Job?, String>((ref, bookingRef) {
  return FirebaseFirestore.instance
      .collection('bookings')
      .doc(bookingRef)
      .snapshots()
      .map((snap) => snap.exists ? Job.fromFirestore(snap) : null);
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatTimer(Duration d) {
  final h = d.inHours.toString().padLeft(2, '0');
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String _formatPKR(double p) => p
    .toStringAsFixed(0)
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

List<TimelineStep> _buildSteps(Job job) {
  final statusOrder = [
    JobStatus.enRoute,
    JobStatus.arrived,
    JobStatus.inProgress,
    JobStatus.completed,
  ];
  final timestamps = {
    JobStatus.enRoute: job.acceptedAt,
    JobStatus.arrived: job.arrivedAt,
    JobStatus.inProgress: job.startedAt,
    JobStatus.completed: job.completedAt,
  };
  final labels = {
    JobStatus.enRoute: 'En Route to Customer',
    JobStatus.arrived: 'Arrived at Location',
    JobStatus.inProgress: 'Work in Progress',
    JobStatus.completed: 'Job Completed',
  };

  return statusOrder.map((s) {
    final idx = statusOrder.indexOf(s);
    final currentIdx = statusOrder.indexOf(job.status);
    return TimelineStep(
      status: s.toFirestoreString(),
      label: labels[s]!,
      done: idx < currentIdx,
      isCurrent: s == job.status,
      at: timestamps[s],
    );
  }).toList();
}

bool _jobIsActive(Job job) =>
    job.status == JobStatus.enRoute ||
    job.status == JobStatus.arrived ||
    job.status == JobStatus.inProgress;

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ActiveJobScreen extends ConsumerStatefulWidget {
  final String bookingRef;

  const ActiveJobScreen({super.key, required this.bookingRef});

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  Timer? _workTimer;
  Duration _elapsed = Duration.zero;
  bool _timerRunning = false;

  Timer? _noShowTimer;
  int _noShowSecondsLeft = AppConstants.noShowWaitMinutes * 60;
  bool _noShowActive = false;

  bool _isAdvancing = false;

  @override
  void dispose() {
    _workTimer?.cancel();
    _noShowTimer?.cancel();
    super.dispose();
  }

  void _startWorkTimer(DateTime? startedAt) {
    if (_timerRunning) return;
    final base = startedAt != null
        ? DateTime.now().difference(startedAt)
        : Duration.zero;
    _elapsed = base;
    _timerRunning = true;
    _workTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _startNoShowTimer() {
    if (_noShowActive) return;
    setState(() {
      _noShowActive = true;
      _noShowSecondsLeft = AppConstants.noShowWaitMinutes * 60;
    });
    _noShowTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _noShowSecondsLeft--);
      if (_noShowSecondsLeft <= 0) {
        t.cancel();
        _autoCancelNoShow();
      }
    });
  }

  Future<void> _autoCancelNoShow() async {
    final workerId =
        ref.read(workerProfileProvider).valueOrNull?.id ?? '';
    await ref.read(firestoreServiceProvider).advanceJobStatus(
          widget.bookingRef,
          'cancelled',
          timestampField: 'cancelled_at',
        );
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingRef)
        .update({
      'cancellation_reason': 'no_show',
      'cancelled_by': workerId,
    });
    if (mounted) context.go('/home');
  }

  Future<void> _advance(Job job) async {
    if (_isAdvancing) return;
    setState(() => _isAdvancing = true);

    try {
      switch (job.status) {
        case JobStatus.enRoute:
          await ref.read(firestoreServiceProvider).advanceJobStatus(
                widget.bookingRef,
                'arrived',
                timestampField: 'arrived_at',
              );
          break;

        case JobStatus.arrived:
          final shouldStart = await _promptStartWork();
          if (!shouldStart) break;
          _noShowTimer?.cancel();
          setState(() => _noShowActive = false);
          await ref.read(firestoreServiceProvider).advanceJobStatus(
                widget.bookingRef,
                'in_progress',
                timestampField: 'started_at',
              );
          break;

        case JobStatus.inProgress:
          final confirm = await _confirmComplete();
          if (!confirm) break;
          _workTimer?.cancel();
          setState(() => _timerRunning = false);
          final hours = _elapsed.inSeconds / 3600;
          await ref.read(firestoreServiceProvider).completeJob(
                widget.bookingRef,
                hours,
                job.finalPrice ??
                    (job.priceBreakdown['total'] as num?)?.toDouble() ??
                    0.0,
              );
          if (mounted) context.go('/home');
          break;

        default:
          break;
      }
    } finally {
      if (mounted) setState(() => _isAdvancing = false);
    }
  }

  Future<bool> _promptStartWork() async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Start Work?'),
          content: const Text(
            'Add "before" photos before starting the job — this protects '
            'you in case of any disputes.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not yet')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Start Work')),
          ],
        ),
      ) ??
      false;

  Future<bool> _confirmComplete() async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Complete Job?'),
          content: const Text(
            'Make sure you have finished all work and added after-photos '
            'before marking as complete.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Complete Job')),
          ],
        ),
      ) ??
      false;

  Future<void> _callSupport() async {
    final uri = Uri(scheme: 'tel', path: '+923001234567');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _updatePhotos(String field, List<String> photos) async {
    await ref
        .read(firestoreServiceProvider)
        .updateJobPhotos(widget.bookingRef, field, photos);
  }

  Future<void> _addExtraWork(Map<String, dynamic> extra) async {
    await ref
        .read(firestoreServiceProvider)
        .addExtraWork(widget.bookingRef, extra);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Extra work sent for customer approval.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobAsync = ref.watch(_jobStreamProvider(widget.bookingRef));

    return jobAsync.when(
      data: (job) {
        if (job == null) {
          return Scaffold(
            body: Center(
                child: Text('Job not found', style: theme.textTheme.bodyLarge)),
          );
        }

        if (job.status == JobStatus.inProgress) {
          _startWorkTimer(job.startedAt);
        }

        return Scaffold(
          backgroundColor: WorkerColors.background,
          floatingActionButton: FloatingActionButton(
            heroTag: 'chat_fab',
            onPressed: () =>
                context.go('/job/${widget.bookingRef}/chat'),
            tooltip: 'Chat with Customer',
            child: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // ── Custom AppBar ────────────────────────────────────
                _ActiveJobAppBar(
                  bookingRef: widget.bookingRef,
                  onSos: _callSupport,
                ),
                // ── Scrollable body ──────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WorkerSizes.pagePadding,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Customer info
                        _CustomerInfoCard(job: job),
                        const SizedBox(height: 16),
                        // 2. Timeline
                        TimelineStepper(
                          steps: _buildSteps(job),
                          onAdvance: _jobIsActive(job)
                              ? () => _advance(job)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // 3. Work timer (in_progress only)
                        if (job.status == JobStatus.inProgress) ...[
                          _WorkTimer(elapsed: _elapsed),
                          const SizedBox(height: 16),
                        ],
                        // 4. Price breakdown
                        _PriceBreakdownCard(job: job),
                        const SizedBox(height: 16),
                        // 5. Photos
                        Container(
                          padding:
                              const EdgeInsets.all(WorkerSizes.cardPadding),
                          decoration: BoxDecoration(
                            color: WorkerColors.surface,
                            borderRadius: BorderRadius.circular(
                                WorkerSizes.cardRadius),
                            boxShadow: WorkerColors.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Photos',
                                  style: theme.textTheme.titleLarge),
                              const SizedBox(height: 16),
                              PhotoCapture(
                                label: 'Before Photos',
                                existingPhotos: job.photosBefore,
                                onPhotosChanged: (p) =>
                                    _updatePhotos('photos_before', p),
                              ),
                              const SizedBox(height: 16),
                              PhotoCapture(
                                label: 'After Photos',
                                existingPhotos: job.photosAfter,
                                onPhotosChanged: (p) =>
                                    _updatePhotos('photos_after', p),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 6. Extra work
                        SizedBox(
                          height: WorkerSizes.minTouchTarget,
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 18),
                            label: const Text('Add Extra Work +'),
                            onPressed: () => showExtraWorkSheet(
                              context,
                              onSubmit: _addExtraWork,
                            ),
                          ),
                        ),
                        // Customer not home
                        if (job.status == JobStatus.arrived) ...[
                          const SizedBox(height: 12),
                          _CustomerNotHomeButton(
                            isActive: _noShowActive,
                            secondsLeft: _noShowSecondsLeft,
                            onTap:
                                _noShowActive ? null : _startNoShowTimer,
                          ),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                // ── Bottom action button ─────────────────────────────
                if (_jobIsActive(job))
                  _BottomActionButton(
                    job: job,
                    isLoading: _isAdvancing,
                    onTap: () => _advance(job),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: WorkerColors.accent),
        ),
      ),
      error: (e, __) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom AppBar
// ---------------------------------------------------------------------------

class _ActiveJobAppBar extends StatelessWidget {
  final String bookingRef;
  final VoidCallback onSos;

  const _ActiveJobAppBar(
      {required this.bookingRef, required this.onSos});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortRef = 'HMZ-${bookingRef.substring(0, bookingRef.length.clamp(0, 8)).toUpperCase()}';

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      color: WorkerColors.background,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: WorkerColors.text),
            onPressed: () => context.go('/home'),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Job', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: WorkerColors.accentLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    shortRef,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: WorkerColors.accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onSos,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: WorkerColors.errorLight,
                shape: BoxShape.circle,
                border: Border.all(color: WorkerColors.error, width: 1.5),
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: WorkerColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer info card
// ---------------------------------------------------------------------------

class _CustomerInfoCard extends StatelessWidget {
  final Job job;
  const _CustomerInfoCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAddress = job.status == JobStatus.arrived ||
        job.status == JobStatus.inProgress ||
        job.status == JobStatus.completed;

    return Container(
      padding: const EdgeInsets.all(WorkerSizes.cardPadding),
      decoration: BoxDecoration(
        color: WorkerColors.surface,
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        boxShadow: WorkerColors.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: WorkerColors.accentLight,
            child: Text(
              job.customerName.isNotEmpty
                  ? job.customerName[0].toUpperCase()
                  : 'C',
              style: theme.textTheme.titleLarge?.copyWith(
                color: WorkerColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.customerName.split(' ').first,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: WorkerColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        showAddress ? job.customerAddress : job.zone,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: WorkerColors.accentLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '~${job.distanceKm.toStringAsFixed(1)} km',
              style: theme.textTheme.labelSmall?.copyWith(
                color: WorkerColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Work timer
// ---------------------------------------------------------------------------

class _WorkTimer extends StatelessWidget {
  final Duration elapsed;
  const _WorkTimer({required this.elapsed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: WorkerColors.surface,
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        boxShadow: WorkerColors.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            _formatTimer(elapsed),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: WorkerColors.accent,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text('Time on Job',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Price breakdown card
// ---------------------------------------------------------------------------

class _PriceBreakdownCard extends StatelessWidget {
  final Job job;
  const _PriceBreakdownCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pb = job.priceBreakdown;
    final base = (pb['base'] as num?)?.toDouble() ?? 0.0;
    final urgencyFee = (pb['urgency_fee'] as num?)?.toDouble() ?? 0.0;
    final distanceFee = (pb['distance_fee'] as num?)?.toDouble() ?? 0.0;
    final total = (pb['total'] as num?)?.toDouble() ??
        (base + urgencyFee + distanceFee);

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
          Text('Price Breakdown', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          _PriceRow(
              label: 'Base Rate',
              value: 'PKR ${_formatPKR(base)}',
              theme: theme),
          if (urgencyFee > 0)
            _PriceRow(
              label: 'Urgency Fee',
              value: 'PKR ${_formatPKR(urgencyFee)}',
              valueColor: WorkerColors.warning,
              theme: theme,
            ),
          if (distanceFee > 0)
            _PriceRow(
              label: 'Distance Fee',
              value: 'PKR ${_formatPKR(distanceFee)}',
              theme: theme,
            ),
          ...job.extraWork.map((e) {
            final approved = e['approved'] as bool? ?? false;
            final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
            final desc = e['description'] as String? ?? 'Extra Work';
            return _PriceRow(
              label: '+ $desc',
              value: 'PKR ${_formatPKR(amt)}',
              valueColor:
                  approved ? WorkerColors.success : WorkerColors.textMuted,
              suffix: approved ? null : ' (pending)',
              theme: theme,
            );
          }),
          const Divider(height: 20),
          Row(
            children: [
              Text('Total',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                'PKR ${_formatPKR(total)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: WorkerColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? suffix;
  final ThemeData theme;

  const _PriceRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.suffix,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${label}${suffix ?? ''}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: WorkerColors.textMuted),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? WorkerColors.text),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Bottom action button
// ---------------------------------------------------------------------------

class _BottomActionButton extends StatelessWidget {
  final Job job;
  final bool isLoading;
  final VoidCallback onTap;

  const _BottomActionButton({
    required this.job,
    required this.isLoading,
    required this.onTap,
  });

  String get _label {
    switch (job.status) {
      case JobStatus.enRoute:
        return "I've Arrived";
      case JobStatus.arrived:
        return 'Start Work';
      case JobStatus.inProgress:
        return 'Complete Job';
      default:
        return 'Update Status';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
          WorkerSizes.pagePadding, 12, WorkerSizes.pagePadding, 24),
      decoration: const BoxDecoration(
        color: WorkerColors.background,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, -4)),
        ],
      ),
      child: SizedBox(
        height: WorkerSizes.minTouchTarget,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onTap,
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_label, style: theme.textTheme.labelLarge),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer not home button
// ---------------------------------------------------------------------------

class _CustomerNotHomeButton extends StatelessWidget {
  final bool isActive;
  final int secondsLeft;
  final VoidCallback? onTap;

  const _CustomerNotHomeButton({
    required this.isActive,
    required this.secondsLeft,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mins = (secondsLeft / 60).ceil();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? WorkerColors.errorLight : WorkerColors.surface,
          borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
          border: Border.all(
              color: isActive ? WorkerColors.error : WorkerColors.divider),
          boxShadow: WorkerColors.cardShadow,
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 20,
              color: isActive
                  ? WorkerColors.error
                  : WorkerColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isActive
                    ? 'Waiting for customer — auto-cancel in ${mins}m'
                    : 'Customer Not Home?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isActive
                      ? WorkerColors.error
                      : WorkerColors.textMuted,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isActive)
              Text(
                '${(secondsLeft / 60).floor()}:'
                '${(secondsLeft % 60).toString().padLeft(2, '0')}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: WorkerColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (!isActive)
              const Icon(Icons.chevron_right_rounded,
                  color: WorkerColors.textLight),
          ],
        ),
      ),
    );
  }
}
