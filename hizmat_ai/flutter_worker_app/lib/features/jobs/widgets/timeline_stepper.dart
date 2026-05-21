import 'package:flutter/material.dart';

import '../../../core/theme.dart';

// ---------------------------------------------------------------------------
// Data model for a single timeline step
// ---------------------------------------------------------------------------

class TimelineStep {
  final String status;
  final String label;
  final bool done;
  final bool isCurrent;
  final DateTime? at;

  const TimelineStep({
    required this.status,
    required this.label,
    required this.done,
    required this.isCurrent,
    this.at,
  });
}

// ---------------------------------------------------------------------------
// TimelineStepper widget
// ---------------------------------------------------------------------------

class TimelineStepper extends StatefulWidget {
  final List<TimelineStep> steps;
  /// Called when the user taps the advance button on the current step.
  /// Pass null to render the stepper in read-only mode (no advance button).
  final VoidCallback? onAdvance;

  const TimelineStepper({
    super.key,
    required this.steps,
    this.onAdvance,
  });

  @override
  State<TimelineStepper> createState() => _TimelineStepperState();
}

class _TimelineStepperState extends State<TimelineStepper>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Job Timeline', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          ...widget.steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isLast = i == widget.steps.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Circle + line ──────────────────────────────────
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        _StepCircle(
                          step: step,
                          pulseScale: _pulseScale,
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: step.done
                                  ? WorkerColors.success
                                  : WorkerColors.divider,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ── Step content ───────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.label,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: step.done
                                        ? WorkerColors.text
                                        : step.isCurrent
                                            ? WorkerColors.accent
                                            : WorkerColors.textMuted,
                                    fontWeight: step.isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                if (step.at != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTime(step.at!),
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                          color: step.done
                                              ? WorkerColors.success
                                              : WorkerColors.textMuted,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Advance button on current step (non-read-only)
                          if (step.isCurrent && widget.onAdvance != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: widget.onAdvance,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: WorkerColors.accentLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: WorkerColors.accent, width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 14,
                                      color: WorkerColors.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Done',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: WorkerColors.accent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step circle
// ---------------------------------------------------------------------------

class _StepCircle extends StatelessWidget {
  final TimelineStep step;
  final Animation<double> pulseScale;

  const _StepCircle({required this.step, required this.pulseScale});

  @override
  Widget build(BuildContext context) {
    if (step.done) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: WorkerColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      );
    }

    if (step.isCurrent) {
      return AnimatedBuilder(
        animation: pulseScale,
        builder: (_, child) => Transform.scale(
          scale: pulseScale.value,
          child: child,
        ),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: WorkerColors.accentLight,
            shape: BoxShape.circle,
            border: Border.all(color: WorkerColors.accent, width: 2),
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: WorkerColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }

    // Future step
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: WorkerColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: WorkerColors.divider, width: 2),
      ),
    );
  }
}
