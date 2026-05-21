import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // Header
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.home_repair_service_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to HizmatAI',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 150.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'How would you like to continue?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 250.ms),
                ],
              ),

              const SizedBox(height: 52),

              // Customer card
              _RoleCard(
                icon: Icons.person_search_rounded,
                gradient: const [Color(0xFF00D4AA), Color(0xFF00B894)],
                glowColor: AppColors.primary,
                title: 'I\'m a Customer',
                subtitle: 'Book electricians, plumbers, AC technicians, cleaners & more',
                chips: const ['Google Sign-In', 'AI Chat Booking'],
                onTap: () => context.go('/login'),
              ).animate().fadeIn(duration: 400.ms, delay: 350.ms).slideY(begin: 0.3, end: 0),

              const SizedBox(height: 20),

              // Worker card
              _RoleCard(
                icon: Icons.construction_rounded,
                gradient: const [Color(0xFFFF6B35), Color(0xFFE05520)],
                glowColor: const Color(0xFFFF6B35),
                title: 'I\'m a Service Provider',
                subtitle: 'Register as a worker and start getting job requests',
                chips: const ['Google Sign-In', 'Earn Money'],
                onTap: () => context.go('/worker-login'),
              ).animate().fadeIn(duration: 400.ms, delay: 450.ms).slideY(begin: 0.3, end: 0),

              const Spacer(),

              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Powered by Google ADK & Gemini 2.5 Flash',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final Color glowColor;
  final String title;
  final String subtitle;
  final List<String> chips;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: gradient),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 18),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: chips.map((chip) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: glowColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: glowColor.withOpacity(0.15)),
                        ),
                        child: Text(
                          chip,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: glowColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Arrow
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: glowColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: glowColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
