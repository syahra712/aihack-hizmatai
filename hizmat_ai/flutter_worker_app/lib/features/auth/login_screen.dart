import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../providers/worker_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      final firestore = ref.read(firestoreServiceProvider);
      final profile = await firestore.getWorkerByUid(user.uid);
      if (!mounted) return;
      if (profile == null) {
        context.go('/register');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: WorkerColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: WorkerSizes.pagePadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.height - 80),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),

                  // ── Brand block ──────────────────────────────────────────
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: WorkerColors.accentLight,
                          ),
                        ),
                        // Inner icon container
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF8C5A),
                                WorkerColors.accent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: WorkerColors.accent.withOpacity(0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.construction_rounded,
                            size: 46,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'HizmatAI',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: WorkerColors.text,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Center(
                    child: Text(
                      'Service Provider Portal',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: WorkerColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Feature highlights ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: WorkerColors.surface,
                      borderRadius:
                          BorderRadius.circular(WorkerSizes.cardRadius),
                      border: Border.all(color: WorkerColors.divider),
                      boxShadow: WorkerColors.cardShadow,
                    ),
                    child: Column(
                      children: [
                        _FeatureRow(
                          icon: Icons.work_rounded,
                          label: 'Manage jobs & bookings',
                        ),
                        const SizedBox(height: 14),
                        _FeatureRow(
                          icon: Icons.payments_rounded,
                          label: 'Track your earnings',
                        ),
                        const SizedBox(height: 14),
                        _FeatureRow(
                          icon: Icons.star_rounded,
                          label: 'Build your reputation',
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  const SizedBox(height: 32),

                  // ── Sign-in button ───────────────────────────────────────
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: CircularProgressIndicator(
                          color: WorkerColors.accent,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  else
                    _GoogleSignInButton(onTap: _handleGoogleSignIn),

                  const SizedBox(height: 16),

                  // ── Terms ────────────────────────────────────────────────
                  Center(
                    child: Text(
                      'By continuing you agree to our Terms of Service\nand Privacy Policy',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: WorkerColors.textLight,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable widgets
// ---------------------------------------------------------------------------

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: WorkerColors.accentLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: WorkerColors.accent),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: WorkerColors.text,
              ),
        ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GoogleSignInButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: WorkerSizes.minTouchTarget + 4,
        decoration: BoxDecoration(
          color: WorkerColors.surface,
          borderRadius: BorderRadius.circular(WorkerSizes.buttonRadius),
          border: Border.all(color: WorkerColors.divider, width: 1.5),
          boxShadow: WorkerColors.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" badge
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: WorkerColors.text,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
