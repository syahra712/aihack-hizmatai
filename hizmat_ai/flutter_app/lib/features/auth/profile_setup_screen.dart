import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _selectedCity = AppConstants.cities.first;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your name', style: GoogleFonts.poppins()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        context.go('/login');
        return;
      }
      final phone = _phoneCtrl.text.trim();
      final user = HizmatUser(
        uid: firebaseUser.uid,
        name: name,
        city: _selectedCity,
        phone: phone.isNotEmpty ? '+92$phone' : null,
        profilePhotoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );
      await ref.read(userServiceProvider).createOrUpdateProfile(user);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: GoogleFonts.poppins()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Tell us about yourself',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.text),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete your profile to get started.',
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),
            Text('Full Name', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.poppins(fontSize: 15, color: AppColors.text),
              decoration: const InputDecoration(hintText: 'e.g. Ahmed Khan'),
            ),
            const SizedBox(height: 20),
            Text('City', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCity,
                  isExpanded: true,
                  style: GoogleFonts.poppins(fontSize: 15, color: AppColors.text),
                  dropdownColor: AppColors.surface,
                  items: AppConstants.cities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCity = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Phone Number (optional)', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(fontSize: 15, color: AppColors.text),
              decoration: const InputDecoration(
                hintText: '3001234567',
                prefixText: '+92 ',
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text('Get Started', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
