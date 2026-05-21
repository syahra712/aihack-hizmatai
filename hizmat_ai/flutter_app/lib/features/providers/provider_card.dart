import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/provider.dart';

class ProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final int rank;
  final VoidCallback onBook;
  final bool loading;
  const ProviderCard({super.key, required this.provider, required this.rank, required this.onBook, this.loading = false});

  bool get _isTop => rank == 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: _isTop ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5) : null,
        boxShadow: _isTop ? AppShadows.card : AppShadows.soft,
        gradient: _isTop
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary.withOpacity(0.03), Colors.white],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildMetaRow(),
          const SizedBox(height: 14),
          _buildScoreSection(),
          if (provider.whyChosen != null) ...[
            const SizedBox(height: 14),
            _buildWhyChosen(),
          ],
          const SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              provider.initials,
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.name,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.star_rounded, size: 13, color: AppColors.amber),
                  const SizedBox(width: 3),
                  Text('${provider.rating}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.amber)),
                  const SizedBox(width: 6),
                  Text('${provider.zone} · ${provider.city}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
        if (provider.scores != null)
          _ScoreCircle(score: provider.scores!.overall, isTop: _isTop),
      ],
    );
  }

  Widget _buildMetaRow() {
    return Row(
      children: [
        _MetaChip(icon: Icons.location_on_rounded, label: provider.zone, color: AppColors.textMuted),
        const SizedBox(width: 8),
        _MetaChip(icon: Icons.work_rounded, label: '${provider.jobsCompleted} jobs', color: AppColors.textMuted),
        const SizedBox(width: 8),
        _MetaChip(icon: Icons.timer_rounded, label: '${provider.responseMinutes} min', color: AppColors.textMuted),
      ],
    );
  }

  Widget _buildScoreSection() {
    if (provider.scores == null) return const SizedBox.shrink();
    final s = provider.scores!;
    final bars = [
      ('Rating', s.ratingScore, const Color(0xFF10B981)),
      ('Experience', s.experience, const Color(0xFF3B82F6)),
      ('Response', s.responseTime, const Color(0xFF8B5CF6)),
      ('Completion', s.completion, const Color(0xFF0891B2)),
      ('Certified', s.certified, const Color(0xFFF59E0B)),
      ('Price Value', s.priceValue, const Color(0xFFEF4444)),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: bars.map((b) {
          final (label, value, color) = b;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: _AnimatedBar(value: value / 100.0, color: color),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 26,
                  child: Text('$value', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: color), textAlign: TextAlign.right),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWhyChosen() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 14, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.whyChosen!,
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.primaryDim, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Est. Price', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted)),
            Text(
              'PKR ${provider.priceEstimate}',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text),
            ),
          ],
        ),
        if (provider.isCertified) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text('Certified', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
              ],
            ),
          ),
        ],
        const Spacer(),
        if (_isTop)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00B894)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppShadows.primaryGlow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, size: 12, color: Colors.white),
                const SizedBox(width: 3),
                Text('AI Top Pick', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        GestureDetector(
          onTap: loading ? null : onBook,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00B894)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppShadows.primaryGlow,
            ),
            child: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Book Now', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class _ScoreCircle extends StatefulWidget {
  final int score;
  final bool isTop;
  const _ScoreCircle({required this.score, required this.isTop});

  @override
  State<_ScoreCircle> createState() => _ScoreCircleState();
}

class _ScoreCircleState extends State<_ScoreCircle> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        return SizedBox(
          width: 48,
          height: 48,
          child: CustomPaint(
            painter: _CirclePainter(
              progress: _anim.value * widget.score / 100,
              color: widget.isTop ? AppColors.primary : AppColors.accent,
            ),
            child: Center(
              child: Text(
                '${(widget.score * _anim.value).round()}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: widget.isTop ? AppColors.primary : AppColors.accent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  _CirclePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = color.withOpacity(0.12),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter old) => old.progress != progress;
}

class _AnimatedBar extends StatefulWidget {
  final double value;
  final Color color;
  const _AnimatedBar({required this.value, required this.color});

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: widget.value * _anim.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(label, style: GoogleFonts.poppins(fontSize: 10, color: color), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

