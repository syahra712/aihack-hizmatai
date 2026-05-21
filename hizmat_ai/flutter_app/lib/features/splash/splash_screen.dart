import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    Future.delayed(AppConstants.splashDuration, _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    context.go('/onboarding');
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF0FBF7), Color(0xFFE0F8EF)],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (context, _) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ParticlePainter(_particleCtrl.value),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
                      ),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 40, spreadRadius: 4),
                        BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 80, spreadRadius: 20),
                      ],
                    ),
                    child: const Icon(Icons.home_repair_service_rounded, size: 50, color: Colors.white),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06), duration: 1500.ms, curve: Curves.easeInOut),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Hizmat', style: GoogleFonts.poppins(fontSize: 38, fontWeight: FontWeight.w800, color: AppColors.text)),
                      Text('AI', style: GoogleFonts.poppins(fontSize: 38, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ],
                  ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.tagline,
                    style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textMuted, fontWeight: FontWeight.w500, letterSpacing: 0.3),
                  ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
                  const SizedBox(height: 56),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 900.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = Random(42);

    for (int i = 0; i < 25; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble() * 2 * pi;

      final x = baseX + sin(progress * 2 * pi * speed + phase) * 18;
      final y = baseY + cos(progress * 2 * pi * speed + phase) * 14;
      final opacity = 0.06 + sin(progress * 2 * pi + phase) * 0.04;
      final radius = 2.0 + rng.nextDouble() * 4.0;

      paint.color = AppColors.primary.withOpacity(opacity.clamp(0.02, 0.12));
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
