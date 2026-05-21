import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../models/worker_profile.dart';
import '../../providers/worker_providers.dart';

// ---------------------------------------------------------------------------
// Data helpers
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  final Map<String, dynamic> _data = {};

  final _nameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _customTagController = TextEditingController();
  final _rateController = TextEditingController();
  final _accountController = TextEditingController();
  final _nameFormKey = GlobalKey<FormState>();
  final _cnicFormKey = GlobalKey<FormState>();

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
    _pageController.dispose();
    _nameController.dispose();
    _cnicController.dispose();
    _customTagController.dispose();
    _rateController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 7) {
      _submit();
      return;
    }
    if (!_validateCurrentStep()) return;
    _collectCurrentStep();
    setState(() => _currentStep++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _nameFormKey.currentState?.validate() ?? false;
      case 1:
        return _cnicFormKey.currentState?.validate() ?? false;
      case 2:
        if (_selectedServices.isEmpty) {
          _showError('Please select at least one service type');
          return false;
        }
        return true;
      case 4:
        if (_selectedCity == null) {
          _showError('Please select your city');
          return false;
        }
        if (_selectedZones.isEmpty) {
          _showError('Please select at least one zone');
          return false;
        }
        return true;
      case 5:
        if (_rateController.text.trim().isEmpty) {
          _showError('Please enter your hourly rate');
          return false;
        }
        return true;
      case 6:
        if (_selectedDays.isEmpty) {
          _showError('Please select at least one available day');
          return false;
        }
        if (_selectedSlots.isEmpty) {
          _showError('Please select at least one time slot');
          return false;
        }
        return true;
      case 7:
        if (_accountController.text.trim().isEmpty) {
          _showError('Please enter your payout account number');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _collectCurrentStep() {
    switch (_currentStep) {
      case 0:
        _data['name'] = _nameController.text.trim();
        _data['profile_photo'] = _profilePhoto?.path;
        break;
      case 1:
        _data['cnic'] = _cnicController.text.trim();
        break;
      case 2:
        _data['service_types'] = _selectedServices.toList();
        break;
      case 3:
        _data['specializations'] = _selectedTags.toList();
        break;
      case 4:
        _data['city'] = _selectedCity;
        _data['zones'] = _selectedZones.toList();
        break;
      case 5:
        _data['hourly_rate'] =
            double.tryParse(_rateController.text.trim()) ?? 0.0;
        break;
      case 6:
        _data['available_days'] = _selectedDays.toList();
        _data['available_slots'] = _selectedSlots.toList();
        break;
      case 7:
        _data['payout_method'] = _payoutMethod;
        _data['payout_account'] = _accountController.text.trim();
        break;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
    _collectCurrentStep();
    setState(() => _isLoading = true);

    try {
      final authUser = ref.read(authStateProvider).valueOrNull;
      if (authUser == null) throw Exception('Not authenticated');

      final firestore = ref.read(firestoreServiceProvider);
      final profile = WorkerProfile(
        id: authUser.uid,
        uid: authUser.uid,
        name: _data['name'] as String? ?? '',
        phone: authUser.email ?? '',
        cnic: _data['cnic'] as String? ?? '',
        profilePhotoUrl: '',
        serviceType:
            (_data['service_types'] as List<dynamic>?)?.isNotEmpty == true
                ? (_data['service_types'] as List<dynamic>).first as String
                : '',
        specializations:
            (_data['specializations'] as List<dynamic>?)?.cast<String>() ?? [],
        hourlyRate: (_data['hourly_rate'] as num?)?.toDouble() ?? 0.0,
        certifications: const [],
        city: _data['city'] as String? ?? '',
        zone: (_data['zones'] as List<dynamic>?)?.isNotEmpty == true
            ? (_data['zones'] as List<dynamic>).first as String
            : '',
        lat: 0.0,
        lng: 0.0,
        isAvailable: false,
        isOnJob: false,
        vacationMode: false,
        availableSlots:
            (_data['available_slots'] as List<dynamic>?)?.cast<String>() ?? [],
        bufferMinutes: 15,
        rating: 0.0,
        reviewCount: 0,
        totalJobs: 0,
        onTimeScore: 0.0,
        cancellationRate: 0.0,
        completionRate: 0.0,
        avgResponseSeconds: 0,
        payoutMethod: _data['payout_method'] as String? ?? '',
        payoutAccount: _data['payout_account'] as String? ?? '',
        appVersion: '1.0.0',
        isVerified: false,
        isSuspended: false,
      );

      await firestore.createWorkerProfile(profile);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Registration failed. Please try again.');
    }
  }

  // ── Step builders ─────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Form(
      key: _nameFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepTitle('Personal Info', 'Tell us about yourself'),
          const SizedBox(height: 28),
          Center(
            child: GestureDetector(
              onTap: _showPhotoPicker,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: WorkerColors.accentLight,
                    backgroundImage: _profilePhoto != null
                        ? FileImage(_profilePhoto!)
                        : null,
                    child: _profilePhoto == null
                        ? const Icon(Icons.person_rounded,
                            size: 52, color: WorkerColors.accent)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: WorkerColors.accent,
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
          const SizedBox(height: 8),
          Center(
            child: Text('Tap to add photo',
                style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(height: 28),
          _label('Full Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'e.g. Muhammad Ali',
              prefixIcon: Icon(Icons.person_outline_rounded,
                  color: WorkerColors.textMuted),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name is required';
              if (v.trim().length < 3) {
                return 'Name must be at least 3 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _cnicFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepTitle('Identity Verification', 'Enter your CNIC number'),
          const SizedBox(height: 28),
          _label('CNIC Number'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _cnicController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
              _CnicFormatter(),
            ],
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'xxxxx-xxxxxxx-x',
              prefixIcon: Icon(Icons.credit_card_rounded,
                  color: WorkerColors.textMuted),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'CNIC is required';
              final digits = v.replaceAll('-', '');
              if (digits.length != 13) return 'Enter a valid 13-digit CNIC';
              if (!RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(v)) {
                return 'Format: xxxxx-xxxxxxx-x';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WorkerColors.accentLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: WorkerColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your CNIC is used for verification only and stored securely.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WorkerColors.accent,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Service Type', 'Select the services you provide'),
        const SizedBox(height: 8),
        Text('You can select multiple',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 24),
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
                  color: isSelected
                      ? WorkerColors.accentLight
                      : WorkerColors.surface,
                  borderRadius:
                      BorderRadius.circular(WorkerSizes.cardRadius),
                  border: Border.all(
                    color: isSelected
                        ? WorkerColors.accent
                        : WorkerColors.divider,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: WorkerColors.cardShadow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      svc['icon'] as IconData,
                      size: 32,
                      color: isSelected
                          ? WorkerColors.accent
                          : WorkerColors.textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      svc['label'] as String,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: isSelected
                                    ? WorkerColors.accent
                                    : WorkerColors.text,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Specializations', 'Add your skills and expertise'),
        const SizedBox(height: 24),
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
              backgroundColor: WorkerColors.surface,
              selectedColor: WorkerColors.accentLight,
              checkmarkColor: WorkerColors.accent,
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? WorkerColors.accent : WorkerColors.text,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
              side: BorderSide(
                color:
                    isSelected ? WorkerColors.accent : WorkerColors.divider,
                width: isSelected ? 1.5 : 1,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _label('Add Custom Tag'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _customTagController,
                textCapitalization: TextCapitalization.words,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'e.g. Solar Panel Installation',
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: WorkerSizes.minTouchTarget,
              height: WorkerSizes.minTouchTarget,
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
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(WorkerSizes.buttonRadius),
                  ),
                ),
                child: const Icon(Icons.add_rounded, size: 24),
              ),
            ),
          ],
        ),
        if (_selectedTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          _label('Selected (${_selectedTags.length})'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () =>
                    setState(() => _selectedTags.remove(tag)),
                backgroundColor: WorkerColors.accentLight,
                labelStyle:
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WorkerColors.accent,
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

  Widget _buildStep5() {
    final zones =
        _selectedCity != null ? (_zonesByCity[_selectedCity] ?? []) : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Service Area', 'Where do you provide services?'),
        const SizedBox(height: 24),
        _label('City'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCity,
          hint: const Text('Select City'),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_city_rounded,
                color: WorkerColors.textMuted),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WorkerSizes.inputRadius),
              borderSide: const BorderSide(color: WorkerColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WorkerSizes.inputRadius),
              borderSide:
                  const BorderSide(color: WorkerColors.accent, width: 1.5),
            ),
            filled: true,
            fillColor: WorkerColors.surface,
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
          const SizedBox(height: 20),
          _label('Zones (select all you cover)'),
          const SizedBox(height: 8),
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
                backgroundColor: WorkerColors.surface,
                selectedColor: WorkerColors.accentLight,
                checkmarkColor: WorkerColors.accent,
                labelStyle:
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? WorkerColors.accent
                              : WorkerColors.text,
                        ),
                side: BorderSide(
                  color: isSelected
                      ? WorkerColors.accent
                      : WorkerColors.divider,
                  width: isSelected ? 1.5 : 1,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStep6() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Hourly Rate', 'Set your service rate per hour'),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: WorkerColors.successLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 18, color: WorkerColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Most providers in this area charge PKR 800–1500/hr',
                  style:
                      Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: WorkerColors.success,
                          ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _label('Your Rate (PKR per hour)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _rateController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          decoration: const InputDecoration(
            prefixText: 'PKR  ',
            prefixStyle: TextStyle(
              color: WorkerColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            hintText: '1000',
          ),
        ),
      ],
    );
  }

  Widget _buildStep7() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Availability', 'When are you available to work?'),
        const SizedBox(height: 24),
        _label('Available Days'),
        const SizedBox(height: 12),
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
                  color: isSelected ? WorkerColors.accent : WorkerColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? WorkerColors.accent
                        : WorkerColors.divider,
                  ),
                  boxShadow: isSelected ? WorkerColors.cardShadow : null,
                ),
                child: Text(
                  day,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected ? Colors.white : WorkerColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _label('Time Slots'),
        const SizedBox(height: 12),
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
              backgroundColor: WorkerColors.surface,
              selectedColor: WorkerColors.accentLight,
              checkmarkColor: WorkerColors.accent,
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        isSelected ? WorkerColors.accent : WorkerColors.text,
                  ),
              side: BorderSide(
                color:
                    isSelected ? WorkerColors.accent : WorkerColors.divider,
                width: isSelected ? 1.5 : 1,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep8() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Payout Method', 'How should we pay your earnings?'),
        const SizedBox(height: 24),
        ...['JazzCash', 'EasyPaisa', 'Bank Transfer'].map((method) {
          final isSelected = _payoutMethod == method;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? WorkerColors.accentLight : WorkerColors.surface,
              borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
              border: Border.all(
                color: isSelected ? WorkerColors.accent : WorkerColors.divider,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: WorkerColors.cardShadow,
            ),
            child: RadioListTile<String>(
              value: method,
              groupValue: _payoutMethod,
              onChanged: (v) => setState(() => _payoutMethod = v!),
              activeColor: WorkerColors.accent,
              title: Text(
                method,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected ? WorkerColors.accent : WorkerColors.text,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
              secondary: Icon(
                method == 'JazzCash'
                    ? Icons.phone_android_rounded
                    : method == 'EasyPaisa'
                        ? Icons.account_balance_wallet_rounded
                        : Icons.account_balance_rounded,
                color: isSelected ? WorkerColors.accent : WorkerColors.textMuted,
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        _label('Account / IBAN Number'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _accountController,
          keyboardType: TextInputType.text,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: _payoutMethod == 'Bank Transfer'
                ? 'PK00XXXX0000000000000000'
                : '03XX XXXXXXX',
            prefixIcon: const Icon(Icons.numbers_rounded,
                color: WorkerColors.textMuted),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _stepTitle(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: WorkerColors.textMuted)),
        ],
      );

  Widget _label(String text) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);

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
              leading: const Icon(Icons.camera_alt_rounded,
                  color: WorkerColors.accent),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: WorkerColors.accent),
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [
      _buildStep1(),
      _buildStep2(),
      _buildStep3(),
      _buildStep4(),
      _buildStep5(),
      _buildStep6(),
      _buildStep7(),
      _buildStep8(),
    ];

    return Scaffold(
      backgroundColor: WorkerColors.background,
      appBar: AppBar(
        backgroundColor: WorkerColors.background,
        elevation: 0,
        leading: _currentStep == 0
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => context.go('/login'),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: _isLoading ? null : _prevStep,
              ),
        title: Text(
          'Step ${_currentStep + 1} of 8',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: WorkerColors.textMuted),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Step indicator ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: WorkerSizes.pagePadding, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(8, (i) {
                  final isActive = i == _currentStep;
                  final isDone = i < _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? WorkerColors.accent
                          : isDone
                              ? WorkerColors.accent.withOpacity(0.4)
                              : WorkerColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // ── Page content ──────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: steps
                    .map((step) => SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: WorkerSizes.pagePadding,
                            vertical: 16,
                          ),
                          child: step,
                        ))
                    .toList(),
              ),
            ),
            // ── Action buttons ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WorkerSizes.pagePadding,
                8,
                WorkerSizes.pagePadding,
                24,
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: SizedBox(
                        height: WorkerSizes.minTouchTarget,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _prevStep,
                          child: const Text('Back'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: WorkerSizes.minTouchTarget,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _nextStep,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                _currentStep == 7
                                    ? 'Complete Registration'
                                    : 'Next',
                                style: theme.textTheme.labelLarge,
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

// ---------------------------------------------------------------------------
// CNIC text input formatter: xxxxx-xxxxxxx-x
// ---------------------------------------------------------------------------

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
