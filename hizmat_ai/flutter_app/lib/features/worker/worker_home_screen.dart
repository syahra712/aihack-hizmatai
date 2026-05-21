import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'worker_firestore_service.dart';
import 'worker_providers.dart';

const _kAccent = Color(0xFFFF6B35);

class WorkerHomeScreen extends ConsumerWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(workerAuthStateProvider);
    final profileAsync = ref.watch(workerProfileProvider);

    // Not logged in — go to worker login
    if (authAsync.valueOrNull == null && !authAsync.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go('/worker-login'));
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_kAccent, Color(0xFFE05520)],
                ),
              ),
              child: const Icon(Icons.construction_rounded,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              'HizmatAI Worker',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(workerAuthServiceProvider).signOut();
              if (context.mounted) context.go('/role-select');
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _kAccent),
        ),
        error: (e, _) => Center(
          child: Text('Error loading profile: $e',
              style: GoogleFonts.poppins(color: AppColors.textMuted)),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_rounded,
                      size: 60, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'Profile not found',
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/worker-register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Complete Registration'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: _kAccent,
            onRefresh: () async =>
                ref.invalidate(workerProfileProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Profile card
                _ProfileCard(profile: profile),
                const SizedBox(height: 20),

                // Online toggle
                _AvailabilityToggle(
                  workerId: profile.id,
                  isAvailable: profile.isAvailable,
                ),
                const SizedBox(height: 20),

                // Stats row
                _StatsRow(
                  rating: profile.rating,
                  totalJobs: profile.totalJobs,
                  completionRate: profile.completionRate,
                ),
                const SizedBox(height: 20),

                // Info cards
                _InfoSection(profile: profile),
                const SizedBox(height: 32),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.work_history_rounded,
                        label: 'Job History',
                        color: const Color(0xFF0891B2),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Job history coming soon')),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Earnings',
                        color: const Color(0xFF059669),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Earnings screen coming soon')),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final dynamic profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kAccent, Color(0xFFE05520)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              profile.name.isNotEmpty
                  ? profile.name[0].toUpperCase()
                  : '?',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatServiceType(profile.serviceType),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.city} • ${profile.zone}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (profile.isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatServiceType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
        .join(' ');
  }
}

class _AvailabilityToggle extends ConsumerWidget {
  final String workerId;
  final bool isAvailable;
  const _AvailabilityToggle(
      {required this.workerId, required this.isAvailable});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isAvailable
                  ? const Color(0xFFEAF7EF)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAvailable
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isAvailable
                  ? const Color(0xFF27AE60)
                  : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? 'You\'re Online' : 'You\'re Offline',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  isAvailable
                      ? 'Accepting new job requests'
                      : 'Not receiving job requests',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            activeColor: const Color(0xFF27AE60),
            onChanged: (val) async {
              try {
                await WorkerFirestoreService()
                    .updateAvailability(workerId, val);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final double rating;
  final int totalJobs;
  final double completionRate;

  const _StatsRow({
    required this.rating,
    required this.totalJobs,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            color: const Color(0xFFF59E0B),
            value: rating == 0 ? '—' : rating.toStringAsFixed(1),
            label: 'Rating',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.work_rounded,
            color: const Color(0xFF6C5CE7),
            value: totalJobs.toString(),
            label: 'Jobs Done',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF27AE60),
            value: completionRate == 0
                ? '—'
                : '${(completionRate * 100).toStringAsFixed(0)}%',
            label: 'Completion',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final dynamic profile;
  const _InfoSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Details',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
              icon: Icons.phone_rounded,
              label: 'Phone',
              value: profile.phone.isNotEmpty ? profile.phone : '—'),
          _InfoRow(
              icon: Icons.attach_money_rounded,
              label: 'Hourly Rate',
              value: profile.hourlyRate > 0
                  ? 'PKR ${profile.hourlyRate.toStringAsFixed(0)}/hr'
                  : '—'),
          _InfoRow(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Payout',
              value: profile.payoutMethod.isNotEmpty
                  ? profile.payoutMethod
                  : '—'),
          if (profile.specializations.isNotEmpty)
            _InfoRow(
              icon: Icons.build_circle_rounded,
              label: 'Skills',
              value: (profile.specializations as List).take(3).join(', ') +
                  ((profile.specializations as List).length > 3
                      ? '...'
                      : ''),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _kAccent),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
