import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class _Stage {
  final String key;
  final String label;
  final String desc;
  final IconData icon;
  final Color color;
  const _Stage({required this.key, required this.label, required this.desc, required this.icon, required this.color});
}

const _stages = [
  _Stage(key: 'confirmed', label: 'Confirmed',        desc: 'Booking confirmed & paid',    icon: Icons.check_rounded,           color: Color(0xFF10B981)),
  _Stage(key: 'assigned',  label: 'Provider Notified', desc: 'Provider has been notified',   icon: Icons.bolt_rounded,            color: Color(0xFF6366F1)),
  _Stage(key: 'enroute',   label: 'En Route',          desc: 'Provider is heading to you',   icon: Icons.location_on_rounded,     color: Color(0xFF3B82F6)),
  _Stage(key: 'arrived',   label: 'Arrived',           desc: 'Provider has arrived',         icon: Icons.handyman_rounded,        color: Color(0xFFF59E0B)),
  _Stage(key: 'working',   label: 'In Progress',       desc: 'Service is underway',          icon: Icons.access_time_rounded,     color: Color(0xFF8B5CF6)),
  _Stage(key: 'completed', label: 'Completed',         desc: 'Service completed!',           icon: Icons.star_rounded,            color: Color(0xFF10B981)),
];

const _autoDelays = [0, 3000, 7000, 12000, 18000, 25000];

class LiveTracker extends StatefulWidget {
  final bool active;
  final String providerName;
  const LiveTracker({super.key, this.active = false, required this.providerName});

  @override
  State<LiveTracker> createState() => _LiveTrackerState();
}

class _LiveTrackerState extends State<LiveTracker> {
  int _currentStage = 0;
  int _eta = 12;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    if (widget.active) _startAutoAdvance();
  }

  @override
  void didUpdateWidget(LiveTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _startAutoAdvance();
  }

  void _startAutoAdvance() {
    for (int i = 1; i < _autoDelays.length; i++) {
      final idx = i;
      _timers.add(Timer(Duration(milliseconds: _autoDelays[i]), () {
        if (mounted) setState(() => _currentStage = idx);
      }));
    }
    _timers.add(Timer.periodic(const Duration(milliseconds: 2500), (t) {
      if (!mounted || _currentStage < 2 || _currentStage >= 5) { t.cancel(); return; }
      setState(() => _eta = (_eta - 1).clamp(0, 99));
    }));
  }

  @override
  void dispose() {
    for (final t in _timers) { t.cancel(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          ..._stages.asMap().entries.map((e) => _buildStep(e.key, e.value)),
          if (_currentStage == 5) _buildCompleteBanner(),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _PulsingDot(),
        const SizedBox(width: 8),
        Text('LIVE', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFEF4444), letterSpacing: 1)),
        const SizedBox(width: 8),
        Text('Tracking your booking', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        const Spacer(),
        if (_currentStage >= 2 && _currentStage < 5)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('~$_eta min', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
      ],
    );
  }

  Widget _buildStep(int index, _Stage stage) {
    final done = index < _currentStage;
    final isCurrent = index == _currentStage;

    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              if (index > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 2, height: 20,
                  decoration: BoxDecoration(
                    color: done ? AppColors.primary : AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                width: isCurrent ? 32 : 28,
                height: isCurrent ? 32 : 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.primary : isCurrent ? stage.color : AppColors.surfaceLight,
                  border: Border.all(
                    color: done ? AppColors.primary : isCurrent ? stage.color : AppColors.cardBorder,
                    width: 2,
                  ),
                  boxShadow: isCurrent ? [BoxShadow(color: stage.color.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)] : [],
                ),
                child: Icon(
                  done ? Icons.check_rounded : stage.icon,
                  size: isCurrent ? 15 : 13,
                  color: (done || isCurrent) ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: index > 0 ? 24 : 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent ? AppColors.text : done ? AppColors.textMuted : AppColors.textMuted.withOpacity(0.6),
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                  if (isCurrent)
                    Text(
                      stage.desc,
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                    ).animate().fadeIn(duration: 300.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Service completed! Rate ${widget.providerName} to help others.',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }
}

class _PulsingDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8, height: 8,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEF4444),
      ),
    ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 750.ms).then().fadeOut(duration: 750.ms);
  }
}
