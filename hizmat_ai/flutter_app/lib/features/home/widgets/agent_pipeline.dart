import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';

class AgentPipelineStep {
  final String name;
  final IconData icon;
  final Color color;
  const AgentPipelineStep({required this.name, required this.icon, required this.color});
}

const pipelineSteps = [
  AgentPipelineStep(name: 'Intent', icon: Icons.psychology_rounded, color: Color(0xFF7C3AED)),
  AgentPipelineStep(name: 'Discovery', icon: Icons.search_rounded, color: Color(0xFF0891B2)),
  AgentPipelineStep(name: 'Ranking', icon: Icons.leaderboard_rounded, color: Color(0xFF0284C7)),
  AgentPipelineStep(name: 'Pricing', icon: Icons.receipt_rounded, color: Color(0xFF059669)),
  AgentPipelineStep(name: 'Booking', icon: Icons.calendar_today_rounded, color: Color(0xFFF59E0B)),
  AgentPipelineStep(name: 'Followup', icon: Icons.support_agent_rounded, color: Color(0xFFEF4444)),
];

class AgentPipeline extends StatelessWidget {
  final int completedCount;
  final int? activeIndex;
  const AgentPipeline({super.key, this.completedCount = 0, this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(pipelineSteps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final prevIdx = i ~/ 2;
                  final done = prevIdx < completedCount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: done ? AppColors.primary.withOpacity(0.6) : AppColors.textMuted.withOpacity(0.3),
                    ),
                  );
                }
                final idx = i ~/ 2;
                final step = pipelineSteps[idx];
                final done = idx < completedCount;
                final active = idx == activeIndex;
                return _PipelinePill(step: step, done: done, active: active);
              }),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: completedCount / pipelineSteps.length,
              minHeight: 3,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }
}

class _PipelinePill extends StatelessWidget {
  final AgentPipelineStep step;
  final bool done;
  final bool active;
  const _PipelinePill({required this.step, required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.primary : active ? step.color : AppColors.textMuted.withOpacity(0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: done
            ? AppColors.primary.withOpacity(0.1)
            : active
                ? step.color.withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: done
              ? AppColors.primary.withOpacity(0.2)
              : active
                  ? step.color.withOpacity(0.3)
                  : Colors.transparent,
        ),
        boxShadow: active
            ? [BoxShadow(color: step.color.withOpacity(0.15), blurRadius: 8)]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : step.icon,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            step.name,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
          if (active) ...[
            const SizedBox(width: 4),
            _PulsingDot(color: step.color),
          ],
        ],
      ),
    );
  }
}

class _PulsingDot extends StatelessWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms);
  }
}
