import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  final _pages = const <_OnboardingPageData>[
    _OnboardingPageData(
      icon: Icons.home_repair_service_rounded,
      iconGradient: [Color(0xFF00D4AA), Color(0xFF00B894)],
      title: 'Welcome to HizmatAI',
      subtitle: 'Pakistan\'s First AI-Powered\nHome Service Platform',
      description:
          'Book electricians, plumbers, AC technicians, cleaners, beauticians & tutors through natural conversation — in Urdu, Roman Urdu, or English.',
      chips: ['Karachi', 'Lahore', 'Islamabad'],
      chipColors: [Color(0xFF00B894), Color(0xFF6C5CE7), Color(0xFF0891B2)],
    ),
    _OnboardingPageData(
      icon: Icons.hub_rounded,
      iconGradient: [Color(0xFF7C3AED), Color(0xFF6C5CE7)],
      title: '6 AI Agents Working\nFor You',
      subtitle: 'Intelligent Pipeline',
      description:
          'Each request passes through a smart agent pipeline — from understanding your need to booking the best provider at the right price.',
      chips: ['Intent', 'Discovery', 'Rank', 'Price', 'Booking', 'Followup'],
      chipColors: [
        Color(0xFF7C3AED),
        Color(0xFF0891B2),
        Color(0xFF0284C7),
        Color(0xFF059669),
        Color(0xFFF59E0B),
        Color(0xFFEF4444),
      ],
    ),
    _OnboardingPageData(
      icon: Icons.auto_awesome_rounded,
      iconGradient: [Color(0xFF0284C7), Color(0xFF0891B2)],
      title: 'Powered by\nGoogle ADK',
      subtitle: 'Antigravity + Gemini 2.5 Flash',
      description:
          'Google\'s Agent Development Kit orchestrates all decisions. Gemini LLM autonomously picks which agents to call, in what order — with full reasoning transparency.',
      chips: ['ADK v2.0', 'Gemini 2.5', 'Transparent AI'],
      chipColors: [Color(0xFF0284C7), Color(0xFFF59E0B), Color(0xFF00B894)],
    ),
    _OnboardingPageData(
      icon: Icons.rocket_launch_rounded,
      iconGradient: [Color(0xFFFF6B6B), Color(0xFFF59E0B)],
      title: 'See the AI Think',
      subtitle: 'Full Agent Trace Visibility',
      description:
          'Every decision, every score, every reasoning step — visible in real time. Tap the trace button to watch the agents work together.',
      chips: ['Live Trace', 'Agent Reasoning', 'Score Breakdown'],
      chipColors: [Color(0xFF6C5CE7), Color(0xFF00B894), Color(0xFF0284C7)],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(duration: 500.ms, curve: Curves.easeOutCubic);
    } else {
      context.go('/role-select');
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page counter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${_pages.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  if (!isLast)
                    TextButton(
                      onPressed: () => context.go('/role-select'),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _OnboardingPage(
                  data: _pages[i],
                  isActive: i == _currentPage,
                ),
              ),
            ),

            // Bottom section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: 300.ms,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: active ? AppShadows.primaryGlow : [],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // CTA button
                  GestureDetector(
                    onTap: _nextPage,
                    child: AnimatedContainer(
                      duration: 300.ms,
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLast
                              ? [const Color(0xFF00D4AA), const Color(0xFF00B894)]
                              : [AppColors.primary, AppColors.primaryDim],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppShadows.primaryGlow,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLast ? 'Get Started' : 'Next',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLast ? Icons.arrow_forward_rounded : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String subtitle;
  final String description;
  final List<String> chips;
  final List<Color> chipColors;

  const _OnboardingPageData({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.chips,
    required this.chipColors,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final bool isActive;
  const _OnboardingPage({required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: data.iconGradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: data.iconGradient[0].withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: data.iconGradient[1].withOpacity(0.15),
                  blurRadius: 80,
                  spreadRadius: 16,
                ),
              ],
            ),
            child: Icon(data.icon, size: 52, color: Colors.white),
          )
              .animate(target: isActive ? 1 : 0)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 40),

          // Subtitle badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: data.iconGradient[0].withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: data.iconGradient[0].withOpacity(0.15)),
            ),
            child: Text(
              data.subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: data.iconGradient[0],
                letterSpacing: 0.3,
              ),
            ),
          ).animate(target: isActive ? 1 : 0).fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 20),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              height: 1.2,
            ),
          ).animate(target: isActive ? 1 : 0).fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.6,
            ),
          ).animate(target: isActive ? 1 : 0).fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 28),

          // Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(data.chips.length, (i) {
              final color = data.chipColors[i % data.chipColors.length];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.15)),
                ),
                child: Text(
                  data.chips[i],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              )
                  .animate(target: isActive ? 1 : 0)
                  .fadeIn(duration: 300.ms, delay: Duration(milliseconds: 400 + i * 80))
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
            }),
          ),
        ],
      ),
    );
  }
}
