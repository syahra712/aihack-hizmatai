import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedCity;
  bool _saving = false;
  HizmatUser? _originalUser;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _prefill(HizmatUser user) {
    if (_originalUser != null) return;
    _originalUser = user;
    _nameCtrl.text = user.name;
    _selectedCity = user.city.isNotEmpty ? user.city : AppConstants.cities.first;
    final phone = user.phone ?? '';
    _phoneCtrl.text = phone.startsWith('+92') ? phone.substring(3).trim() : phone;
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name cannot be empty', style: GoogleFonts.poppins()), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_originalUser == null) return;
    setState(() => _saving = true);
    try {
      final phone = _phoneCtrl.text.trim();
      final updated = _originalUser!.copyWith(
        name: name,
        city: _selectedCity ?? AppConstants.cities.first,
        phone: phone.isNotEmpty ? '+92$phone' : null,
      );
      await ref.read(userServiceProvider).createOrUpdateProfile(updated);
      ref.invalidate(currentUserProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated!', style: GoogleFonts.poppins()), backgroundColor: AppColors.primary),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e', style: GoogleFonts.poppins()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.text)),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile != null) _prefill(profile);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Full Name', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  style: GoogleFonts.poppins(fontSize: 15, color: AppColors.text),
                  decoration: const InputDecoration(hintText: 'Your name'),
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
                      value: _selectedCity ?? AppConstants.cities.first,
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
                Text('Phone Number', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
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
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text('Save Changes', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
