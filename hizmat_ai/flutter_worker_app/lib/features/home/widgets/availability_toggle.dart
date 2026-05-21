import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../providers/worker_providers.dart';
import '../../../services/location_service.dart';

class AvailabilityToggle extends ConsumerStatefulWidget {
  const AvailabilityToggle({super.key});

  @override
  ConsumerState<AvailabilityToggle> createState() =>
      _AvailabilityToggleState();
}

class _AvailabilityToggleState extends ConsumerState<AvailabilityToggle>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleAvailability(bool newValue) async {
    final profile = ref.read(workerProfileProvider).valueOrNull;
    if (profile == null) return;

    setState(() => _isLoading = true);

    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();

      await ref.read(firestoreServiceProvider).updateAvailability(
            profile.id,
            newValue,
            position?.latitude,
            position?.longitude,
          );
    } catch (_) {
      // Silently fail; Firestore stream will reflect actual state
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(workerProfileProvider).valueOrNull;
    final isOnline = profile?.isAvailable ?? false;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(
        horizontal: WorkerSizes.cardPadding,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: WorkerColors.surface,
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        boxShadow: WorkerColors.cardShadow,
        border: Border.all(
          color: isOnline
              ? WorkerColors.success.withOpacity(0.3)
              : WorkerColors.divider,
          width: isOnline ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // ── Switch + label ───────────────────────────────────────────
          _isLoading
              ? const SizedBox(
                  width: 52,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: WorkerColors.accent,
                      ),
                    ),
                  ),
                )
              : Transform.scale(
                  scale: 1.15,
                  child: Switch(
                    value: isOnline,
                    onChanged: _isLoading ? null : _toggleAvailability,
                    activeColor: WorkerColors.success,
                    activeTrackColor: WorkerColors.successLight,
                    inactiveThumbColor: WorkerColors.textLight,
                    inactiveTrackColor: WorkerColors.divider,
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return WorkerColors.textLight;
                    }),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return WorkerColors.success;
                      }
                      return WorkerColors.divider;
                    }),
                  ),
                ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOnline ? 'Online' : 'Offline',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: isOnline ? WorkerColors.success : WorkerColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isOnline ? 'You are available for jobs' : 'Go online to receive jobs',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const Spacer(),
          // ── Status indicator ─────────────────────────────────────────
          if (isOnline)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => Opacity(
                    opacity: _pulseAnimation.value,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: WorkerColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Receiving\njobs',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WorkerColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: WorkerColors.textLight,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Not receiving\njobs',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WorkerColors.textMuted,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
