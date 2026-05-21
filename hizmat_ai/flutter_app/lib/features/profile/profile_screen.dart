import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../services/firebase_service.dart';
import '../../services/user_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.text)),
      ),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (firebaseUser) {
          return profileAsync.when(
            loading: () => _buildBody(
              context: context,
              ref: ref,
              photoUrl: firebaseUser?.photoURL,
              displayName: '...',
              subtitle: '...',
              firebaseUser: firebaseUser,
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (profile) => _buildBody(
              context: context,
              ref: ref,
              photoUrl: firebaseUser?.photoURL,
              displayName: profile?.name.isNotEmpty == true ? profile!.name : (firebaseUser?.displayName ?? 'User'),
              subtitle: profile?.city ?? '',
              firebaseUser: firebaseUser,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required WidgetRef ref,
    required String? photoUrl,
    required String displayName,
    required String subtitle,
    required dynamic firebaseUser,
  }) {
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              if (photoUrl != null)
                CircleAvatar(
                  radius: 44,
                  backgroundImage: NetworkImage(photoUrl),
                )
              else
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00B894)]),
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.primaryGlow,
                  ),
                  child: Center(
                    child: Text(initials, style: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              const SizedBox(height: 16),
              Text(displayName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMuted)),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 36),
        _SettingsTile(
          icon: Icons.person_rounded,
          label: 'Edit Profile',
          subtitle: 'Name, phone, city',
          onTap: () => context.push('/profile/edit'),
        ),
        _SettingsTile(
          icon: Icons.location_on_rounded,
          label: 'Saved Addresses',
          subtitle: 'Home, office, other',
          onTap: () => context.push('/profile/addresses'),
        ),
        _SettingsTile(icon: Icons.payments_rounded, label: 'Payment Methods', subtitle: 'Cash, JazzCash, Easypaisa'),
        _SettingsTile(icon: Icons.notifications_rounded, label: 'Notifications', subtitle: 'Push & SMS alerts'),
        _SettingsTile(icon: Icons.language_rounded, label: 'Language', subtitle: 'English, Urdu, Roman Urdu'),
        _SettingsTile(icon: Icons.shield_rounded, label: 'Privacy & Security', subtitle: 'Data, permissions'),
        const SizedBox(height: 20),
        _SettingsTile(icon: Icons.help_outline_rounded, label: 'Help & Support', subtitle: 'FAQ, contact us'),
        _SettingsTile(icon: Icons.info_outline_rounded, label: 'About Hizmat AI', subtitle: 'Version 2.0.0'),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: () async {
              await signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
            label: Text('Log Out', style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.label, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
