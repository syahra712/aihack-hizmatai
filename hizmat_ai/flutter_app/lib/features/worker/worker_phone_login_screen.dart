import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

const _kWorkerAccent = Color(0xFFFF6B35);
const _kWorkerAccentLight = Color(0xFFFFF0EB);

class WorkerPhoneLoginScreen extends ConsumerWidget {
  const WorkerPhoneLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.text),
          onPressed: () => context.go('/role-select'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Icon
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: const BoxDecoration(
                        color: _kWorkerAccentLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8C5A), _kWorkerAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _kWorkerAccent.withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.construction_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Service Provider Login',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Create your worker profile and start getting job requests',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // Feature highlights
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: _kWorkerAccentLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kWorkerAccent.withOpacity(0.15)),
                ),
                child: const Column(
                  children: [
                    _FeatureRow(icon: Icons.work_rounded, label: 'Manage jobs & bookings'),
                    SizedBox(height: 16),
                    _FeatureRow(icon: Icons.payments_rounded, label: 'Track your earnings'),
                    SizedBox(height: 16),
                    _FeatureRow(icon: Icons.star_rounded, label: 'Build your reputation'),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              GestureDetector(
                onTap: () => context.go('/worker-register'),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder, width: 1.5),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _kWorkerAccent,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(Icons.construction_rounded,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continue as Service Provider',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'By continuing you agree to our Terms of Service',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _kWorkerAccent),
        const SizedBox(width: 14),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
