import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../models/worker_profile.dart';
import 'worker_providers.dart';

const _kAccent = Color(0xFFFF6B35);
const _kAccentLight = Color(0xFFFFF0EB);
const _kDivider = Color(0xFFECEFF6);

const _serviceCategories = [
  {'key': 'electrician', 'label': 'Electrician', 'icon': Icons.electrical_services_rounded},
  {'key': 'plumber', 'label': 'Plumber', 'icon': Icons.plumbing_rounded},
  {'key': 'ac_repair', 'label': 'AC Technician', 'icon': Icons.ac_unit_rounded},
  {'key': 'home_cleaning', 'label': 'Home Cleaning', 'icon': Icons.cleaning_services_rounded},
  {'key': 'home_tutor', 'label': 'Home Tutor', 'icon': Icons.menu_book_rounded},
  {'key': 'beautician', 'label': 'Beautician', 'icon': Icons.spa_rounded},
];

const _cities = ['Karachi', 'Lahore', 'Islamabad'];

const _zonesByCity = {
  'Karachi': ['DHA', 'Clifton', 'Gulshan', 'PECHS', 'North Nazimabad', 'Malir'],
  'Lahore': ['DHA', 'Gulberg', 'Model Town', 'Johar Town', 'Bahria Town', 'Cantt'],
  'Islamabad': ['F-6', 'F-7', 'F-8', 'G-9', 'G-10', 'E-7'],
};

const _timeSlots = [
  '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM',
  '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM',
  '04:00 PM', '05:00 PM', '06:00 PM', '07:00 PM',
];

const _suggestionTags = [
  'Wiring', 'Fan Installation', 'Circuit Breaker', 'Inverter Setup',
  'Pipe Fitting', 'Tap Repair', 'AC Gas Refill', 'AC Installation',
  'Deep Cleaning', 'O Level Math', 'O Level Physics', 'Bridal Makeup',
];

const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class WorkerRegisterScreen extends ConsumerStatefulWidget {
  const WorkerRegisterScreen({super.key});

  @override
  ConsumerState<WorkerRegisterScreen> createState() =>
      _WorkerRegisterScreenState();
}

class _WorkerRegisterScreenState extends ConsumerState<WorkerRegisterScreen> {
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _customTagController = TextEditingController();
  final _rateController = TextEditingController();
  final _accountController = TextEditingController();

  File? _profilePhoto;
  final _imagePicker = ImagePicker();

  final Set<String> _selectedServices = {};
  final Set<String> _selectedTags = {};

  String? _selectedCity;
  final Set<String> _selectedZones = {};

  final Set<String> _selectedDays = {};
  final Set<String> _selectedSlots = {};

  String _payoutMethod = 'JazzCash';

  @override
  void dispose() {
    _nameController.dispose();
    _cnicController.dispose();
    _customTagController.dispose();
    _rateController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final xFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 600,
    );
    if (xFile != null) setState(() => _profilePhoto = File(xFile.path));
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().length < 3) { _showError('Enter your full name'); return; }
    final cnicDigits = _cnicController.text.replaceAll('-', '');
    if (cnicDigits.length != 13) { _showError('Enter a valid 13-digit CNIC'); return; }
    if (_selectedServices.isEmpty) { _showError('Select at least one service type'); return; }
    if (_selectedCity == null || _selectedZones.isEmpty) { _showError('Select your city and at least one zone'); return; }
    if (_rateController.text.trim().isEmpty) { _showError('Enter your hourly rate'); return; }
    if (_selectedDays.isEmpty || _selectedSlots.isEmpty) { _showError('Select your available days and time slots'); return; }
    if (_accountController.text.trim().isEmpty) { _showError('Enter your payout account number'); return; }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(workerAuthStateProvider).valueOrNull;
      if (authState == null) throw Exception('Not authenticated');

      final firestoreService = ref.read(workerFirestoreServiceProvider);
      final profile = WorkerProfile(
        id: authState.uid,
        uid: authState.uid,
        name: _nameController.text.trim(),
        phone: authState.email ?? '',
        cnic: _cnicController.text.trim(),
        profilePhotoUrl: '',
        serviceType: _selectedServices.isNotEmpty ? _selectedServices.first : '',
        specializations: _selectedTags.toList(),
        hourlyRate: double.tryParse(_rateController.text.trim()) ?? 0.0,
        certifications: const [],
        city: _selectedCity ?? '',
        zone: _selectedZones.isNotEmpty ? _selectedZones.first : '',
        lat: 0.0,
        lng: 0.0,
        isAvailable: false,
        isOnJob: false,
        vacationMode: false,
        availableSlots: _selectedSlots.toList(),
        bufferMinutes: 15,
        rating: 0.0,
        reviewCount: 0,
        totalJobs: 0,
        onTimeScore: 0.0,
        cancellationRate: 0.0,
        completionRate: 0.0,
        avgResponseSeconds: 0,
        payoutMethod: _payoutMethod,
        payoutAccount: _accountController.text.trim(),
        appVersion: '1.0.0',
        isVerified: false,
        isSuspended: false,
      );

      await firestoreService.createWorkerProfile(profile);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hizmat_role_${authState.uid}', 'worker');
      if (!mounted) return;
      context.go('/worker-home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Registration failed. Please try again.');
    }
  }

  // ── Section builders ───────────────────────────────────────────────────────

  Widget _buildIdentitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: GestureDetector(
            onTap: _showPhotoPicker,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: _kAccentLight,
                  backgroundImage: _profilePhoto != null
                      ? FileImage(_profilePhoto!)
                      : null,
                  child: _profilePhoto == null
                      ? const Icon(Icons.person_rounded, size: 52, color: _kAccent)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: _kAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Tap to add photo',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. Muhammad Ali',
            labelText: 'Full Name',
            prefixIcon: const Icon(Icons.person_outline_rounded,
                color: AppColors.textMuted),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _kAccent, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cnicController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(13),
            _CnicFormatter(),
          ],
          decoration: InputDecoration(
            hintText: 'xxxxx-xxxxxxx-x',
            labelText: 'CNIC Number',
            prefixIcon: const Icon(Icons.credit_card_rounded,
                color: AppColors.textMuted),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _kAccent, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kAccentLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: _kAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your CNIC is used for verification only and stored securely.',
                  style: GoogleFonts.poppins(fontSize: 12, color: _kAccent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: _serviceCategories.map((svc) {
            final key = svc['key'] as String;
            final isSelected = _selectedServices.contains(key);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _selectedServices.remove(key);
                } else {
                  _selectedServices.add(key);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected ? _kAccentLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _kAccent : _kDivider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      svc['icon'] as IconData,
                      size: 32,
                      color: isSelected ? _kAccent : AppColors.textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      svc['label'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isSelected ? _kAccent : AppColors.text,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _label('Specializations'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestionTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (v) => setState(() {
                if (v) _selectedTags.add(tag);
                else _selectedTags.remove(tag);
              }),
              backgroundColor: AppColors.surface,
              selectedColor: _kAccentLight,
              checkmarkColor: _kAccent,
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected ? _kAccent : AppColors.text,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isSelected ? _kAccent : _kDivider,
                width: isSelected ? 1.5 : 1,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _customTagController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Solar Panel Installation',
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _kAccent, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 52,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final tag = _customTagController.text.trim();
                  if (tag.isNotEmpty) {
                    setState(() {
                      _selectedTags.add(tag);
                      _customTagController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Icon(Icons.add_rounded, size: 24),
              ),
            ),
          ],
        ),
        if (_selectedTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () => setState(() => _selectedTags.remove(tag)),
                backgroundColor: _kAccentLight,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _kAccent,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide.none,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAreaSection() {
    final zones =
        _selectedCity != null ? (_zonesByCity[_selectedCity] ?? []) : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCity,
          hint: const Text('Select City'),
          decoration: InputDecoration(
            labelText: 'City',
            prefixIcon: const Icon(Icons.location_city_rounded,
                color: AppColors.textMuted),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _kAccent, width: 2),
            ),
          ),
          items: _cities
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() {
            _selectedCity = v;
            _selectedZones.clear();
          }),
        ),
        if (_selectedCity != null) ...[
          const SizedBox(height: 16),
          _label('Zones'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: zones.map((zone) {
              final isSelected = _selectedZones.contains(zone);
              return FilterChip(
                label: Text(zone),
                selected: isSelected,
                onSelected: (v) => setState(() {
                  if (v) _selectedZones.add(zone);
                  else _selectedZones.remove(zone);
                }),
                backgroundColor: AppColors.surface,
                selectedColor: _kAccentLight,
                checkmarkColor: _kAccent,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isSelected ? _kAccent : AppColors.text,
                ),
                side: BorderSide(
                  color: isSelected ? _kAccent : _kDivider,
                  width: isSelected ? 1.5 : 1,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildRatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 18, color: Color(0xFF27AE60)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Most providers in this area charge PKR 800–1500/hr',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF27AE60),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _rateController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
          decoration: InputDecoration(
            prefixText: 'PKR  ',
            prefixStyle: GoogleFonts.poppins(
              color: AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            hintText: '1000',
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _kAccent, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _label('Available Days'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weekDays.map((day) {
            final isSelected = _selectedDays.contains(day);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) _selectedDays.remove(day);
                else _selectedDays.add(day);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _kAccent : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _kAccent : _kDivider,
                  ),
                ),
                child: Text(
                  day,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _label('Time Slots'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeSlots.map((slot) {
            final isSelected = _selectedSlots.contains(slot);
            return FilterChip(
              label: Text(slot),
              selected: isSelected,
              onSelected: (v) => setState(() {
                if (v) _selectedSlots.add(slot);
                else _selectedSlots.remove(slot);
              }),
              backgroundColor: AppColors.surface,
              selectedColor: _kAccentLight,
              checkmarkColor: _kAccent,
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected ? _kAccent : AppColors.text,
              ),
              side: BorderSide(
                color: isSelected ? _kAccent : _kDivider,
                width: isSelected ? 1.5 : 1,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPayoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...['JazzCash', 'EasyPaisa', 'Bank Transfer'].map((method) {
          final isSelected = _payoutMethod == method;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? _kAccentLight : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _kAccent : _kDivider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: RadioListTile<String>(
              value: method,
              groupValue: _payoutMethod,
              onChanged: (v) => setState(() => _payoutMethod = v!),
              activeColor: _kAccent,
              title: Text(
                method,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: isSelected ? _kAccent : AppColors.text,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              secondary: Icon(
                method == 'JazzCash'
                    ? Icons.phone_android_rounded
                    : method == 'EasyPaisa'
                        ? Icons.account_balance_wallet_rounded
                        : Icons.account_balance_rounded,
                color: isSelected ? _kAccent : AppColors.textMuted,
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        TextFormField(
          controller: _accountController,
          decoration: InputDecoration(
            hintText: _payoutMethod == 'Bank Transfer'
                ? 'PK00XXXX0000000000000000'
                : '03XX XXXXXXX',
            labelText: 'Account / IBAN Number',
            prefixIcon: const Icon(Icons.numbers_rounded,
                color: AppColors.textMuted),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _kAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kAccent,
          disabledBackgroundColor: _kAccent.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                'Create Profile',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEFF6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      );

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: _kAccent),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: _kAccent),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.text),
          onPressed: () => context.go('/worker-login'),
        ),
        title: Text(
          'Create Profile',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _sectionCard(title: 'Personal Info', child: _buildIdentitySection()),
                  _sectionCard(title: 'Your Service', child: _buildServiceSection()),
                  _sectionCard(title: 'Service Area', child: _buildAreaSection()),
                  _sectionCard(title: 'Rates & Availability', child: _buildRatesSection()),
                  _sectionCard(title: 'Payout', child: _buildPayoutSection()),
                  const SizedBox(height: 8),
                  _buildSubmitButton(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('-', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 13; i++) {
      if (i == 5 || i == 12) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
