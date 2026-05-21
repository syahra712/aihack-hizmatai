import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/job.dart';
import '../../../providers/worker_providers.dart';

// ---------------------------------------------------------------------------
// Helper — service icon
// ---------------------------------------------------------------------------

IconData _serviceIcon(String serviceType) {
  switch (serviceType) {
    case 'electrician':
      return Icons.electrical_services_rounded;
    case 'plumber':
      return Icons.plumbing_rounded;
    case 'ac_repair':
      return Icons.ac_unit_rounded;
    case 'home_cleaning':
      return Icons.cleaning_services_rounded;
    case 'home_tutor':
      return Icons.menu_book_rounded;
    case 'beautician':
      return Icons.spa_rounded;
    case 'painter':
      return Icons.format_paint_rounded;
    case 'carpenter':
      return Icons.carpenter_rounded;
    default:
      return Icons.build_rounded;
  }
}

String _serviceLabel(String serviceType) {
  const map = {
    'electrician': 'Electrician',
    'plumber': 'Plumber',
    'ac_repair': 'AC Technician',
    'home_cleaning': 'Home Cleaning',
    'home_tutor': 'Home Tutor',
    'beautician': 'Beautician',
    'painter': 'Painter',
    'carpenter': 'Carpenter',
  };
  return map[serviceType] ?? serviceType;
}

// ---------------------------------------------------------------------------
// IncomingJobOverlay
// ---------------------------------------------------------------------------

class IncomingJobOverlay extends ConsumerStatefulWidget {
  final Job job;
  final VoidCallback onDecline;

  const IncomingJobOverlay({
    super.key,
    required this.job,
    required this.onDecline,
  });

  @override
  ConsumerState<IncomingJobOverlay> createState() => _IncomingJobOverlayState();
}

class _IncomingJobOverlayState extends ConsumerState<IncomingJobOverlay>
    with TickerProviderStateMixin {
  static const int _timeoutSeconds = 60;
  int _secondsLeft = _timeoutSeconds;
  Timer? _countdownTimer;
  bool _isAccepting = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late AnimationController _urgencyController;
  late Animation<double> _urgencyOpacity;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the service icon circle
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Urgency blink animation
    _urgencyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _urgencyOpacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _urgencyController, curve: Curves.easeInOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
          widget.onDecline();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _urgencyController.dispose();
    super.dispose();
  }

  Future<void> _acceptJob() async {
    final profile = ref.read(workerProfileProvider).valueOrNull;
    if (profile == null) return;

    _countdownTimer?.cancel();
    setState(() => _isAccepting = true);

    final accepted = await ref
        .read(firestoreServiceProvider)
        .acceptJob(widget.job.ref, profile.id);

    if (!mounted) return;
    setState(() => _isAccepting = false);

    if (accepted) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job already taken by another worker.')),
      );
      widget.onDecline();
    }
  }

  String _formatPrice(double price) =>
      'PKR ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final job = widget.job;
    final totalPrice = (job.priceBreakdown['total'] as num?)?.toDouble() ??
        job.priceBreakdown.values.fold<double>(
            0.0, (sum, v) => sum + ((v as num?)?.toDouble() ?? 0.0));

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Service icon circle ──────────────────────────────────
            AnimatedBuilder(
              animation: _pulseScale,
              builder: (_, child) => Transform.scale(
                scale: _pulseScale.value,
                child: child,
              ),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: WorkerColors.accentLight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: WorkerColors.accent.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _serviceIcon(job.serviceType),
                  size: 44,
                  color: WorkerColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Heading ──────────────────────────────────────────────
            Text(
              'New Job Request!',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _serviceLabel(job.serviceType),
              style: theme.textTheme.titleMedium?.copyWith(
                color: WorkerColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            // ── Zone + distance ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 16, color: WorkerColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  job.zone,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: WorkerColors.accentLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '~${job.distanceKm.toStringAsFixed(1)} km away',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: WorkerColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            // ── Urgency chip ─────────────────────────────────────────
            if (job.isUrgent) ...[
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _urgencyOpacity,
                builder: (_, child) =>
                    Opacity(opacity: _urgencyOpacity.value, child: child),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: WorkerColors.errorLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: WorkerColors.error),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.priority_high_rounded,
                          size: 14, color: WorkerColors.error),
                      const SizedBox(width: 4),
                      Text(
                        'URGENT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: WorkerColors.error,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // ── Price ────────────────────────────────────────────────
            Text(
              _formatPrice(totalPrice),
              style: theme.textTheme.displayMedium?.copyWith(
                color: WorkerColors.success,
                fontWeight: FontWeight.w800,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Estimated total',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // ── Countdown timer ──────────────────────────────────────
            _CountdownTimer(
              secondsLeft: _secondsLeft,
              total: _timeoutSeconds,
            ),
            const SizedBox(height: 20),
            // ── Accept button ────────────────────────────────────────
            SizedBox(
              height: WorkerSizes.minTouchTarget,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAccepting ? null : _acceptJob,
                child: _isAccepting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Accept Job', style: theme.textTheme.labelLarge),
              ),
            ),
            const SizedBox(height: 10),
            // ── Decline button ───────────────────────────────────────
            SizedBox(
              height: WorkerSizes.minTouchTarget,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isAccepting
                    ? null
                    : () {
                        _countdownTimer?.cancel();
                        widget.onDecline();
                      },
                child: const Text('Decline'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Countdown timer widget
// ---------------------------------------------------------------------------

class _CountdownTimer extends StatelessWidget {
  final int secondsLeft;
  final int total;

  const _CountdownTimer({required this.secondsLeft, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = secondsLeft / total;
    final color = secondsLeft > 15
        ? WorkerColors.accent
        : secondsLeft > 5
            ? WorkerColors.warning
            : WorkerColors.error;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 68,
          height: 68,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            backgroundColor: WorkerColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$secondsLeft',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'sec',
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ],
    );
  }
}
