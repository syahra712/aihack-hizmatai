import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../models/worker_profile.dart';
import '../../providers/location_provider.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';

// ---------------------------------------------------------------------------
// Worker Profile Screen
// ---------------------------------------------------------------------------

class WorkerProfileScreen extends ConsumerStatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  ConsumerState<WorkerProfileScreen> createState() =>
      _WorkerProfileScreenState();
}

class _WorkerProfileScreenState
    extends ConsumerState<WorkerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cnicCtrl;
  late final TextEditingController _hourlyRateCtrl;
  late final TextEditingController _accountCtrl;

  // Local editable state
  String? _serviceType;
  List<String> _specializations = [];
  String _city = '';
  List<String> _selectedZones = [];
  int _bufferMinutes = 15;
  bool _vacationMode = false;
  DateTime? _vacationStart;
  DateTime? _vacationEnd;
  String _payoutMethod = 'JazzCash';
  File? _pickedImage;
  bool _isSaving = false;
  bool _isUpdatingGps = false;
  bool _profileLoaded = false;

  WorkerProfile? _initialProfile;

  static const _serviceTypes = [
    'Electrician',
    'Plumber',
    'Cleaner',
    'AC Technician',
    'Painter',
    'Carpenter',
  ];

  static const _cities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Peshawar',
    'Multan',
    'Quetta',
  ];

  static const _zones = [
    'DHA',
    'Gulshan',
    'North Nazimabad',
    'Clifton',
    'PECHS',
    'Bahria Town',
    'F-7',
    'G-10',
    'I-8',
  ];

  static const _payoutMethods = ['JazzCash', 'EasyPaisa', 'Bank'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _cnicCtrl = TextEditingController();
    _hourlyRateCtrl = TextEditingController();
    _accountCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cnicCtrl.dispose();
    _hourlyRateCtrl.dispose();
    _accountCtrl.dispose();
    super.dispose();
  }

  void _populateFromProfile(WorkerProfile profile) {
    if (_profileLoaded) return;
    _profileLoaded = true;
    _initialProfile = profile;

    _nameCtrl.text = profile.name;
    _cnicCtrl.text = _maskCnic(profile.cnic);
    _hourlyRateCtrl.text =
        profile.hourlyRate > 0 ? profile.hourlyRate.toInt().toString() : '';
    _accountCtrl.text = profile.payoutAccount;
    _serviceType = _serviceTypes.firstWhere(
      (s) => s.toLowerCase() == profile.serviceType.toLowerCase(),
      orElse: () => _serviceTypes.first,
    );
    _specializations = List<String>.from(profile.specializations);
    _city = _cities.contains(profile.city) ? profile.city : '';
    _selectedZones = profile.zone.isNotEmpty
        ? profile.zone.split(',').map((z) => z.trim()).toList()
        : [];
    _bufferMinutes = profile.bufferMinutes;
    _vacationMode = profile.vacationMode;
    _vacationStart = profile.vacationStart;
    _vacationEnd = profile.vacationEnd;
    _payoutMethod = _payoutMethods.firstWhere(
      (m) => m.toLowerCase() == profile.payoutMethod.toLowerCase(),
      orElse: () => 'JazzCash',
    );
  }

  String _maskCnic(String cnic) {
    final digits = cnic.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 13) return cnic;
    return '${digits.substring(0, 5)}-${digits.substring(5, 12)}-${digits[12]}';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (xFile != null && mounted) {
      setState(() => _pickedImage = File(xFile.path));
    }
  }

  Future<void> _updateGpsLocation() async {
    setState(() => _isUpdatingGps = true);
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      if (position == null) {
        if (mounted) {
          context.showSnackBar('Could not get GPS location', isError: true);
        }
        return;
      }
      final profile = ref.read(workerProfileProvider).valueOrNull;
      if (profile == null) return;
      await ref.read(firestoreServiceProvider).updateWorkerProfile(
        profile.id,
        {'lat': position.latitude, 'lng': position.longitude},
      );
      if (mounted) context.showSnackBar('GPS location updated');
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to update location', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUpdatingGps = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final profile = _initialProfile ??
        ref.read(workerProfileProvider).valueOrNull;
    if (profile == null) return;

    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'cnic': _cnicCtrl.text.replaceAll('-', '').trim(),
        'service_type': _serviceType?.toLowerCase() ?? '',
        'specializations': _specializations,
        'hourly_rate':
            double.tryParse(_hourlyRateCtrl.text.trim()) ?? 0.0,
        'city': _city,
        'zone': _selectedZones.join(', '),
        'buffer_minutes': _bufferMinutes,
        'vacation_mode': _vacationMode,
        if (_vacationMode && _vacationStart != null)
          'vacation_start': _vacationStart!.millisecondsSinceEpoch,
        if (_vacationMode && _vacationEnd != null)
          'vacation_end': _vacationEnd!.millisecondsSinceEpoch,
        'payout_method': _payoutMethod,
        'payout_account': _accountCtrl.text.trim(),
      };

      await ref
          .read(firestoreServiceProvider)
          .updateWorkerProfile(profile.id, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to save profile', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
            'Are you sure you want to sign out of HizmatAI?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: WorkerColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(authServiceProvider).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(workerProfileProvider);
    final profile = profileAsync.valueOrNull;

    // One-time populate
    if (profile != null && !_profileLoaded) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => setState(() => _populateFromProfile(profile)));
    }

    final phoneNumber = profile?.phone ?? '—';
    final photoUrl = profile?.profilePhotoUrl ?? '';

    return Scaffold(
      backgroundColor: WorkerColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: WorkerColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load profile',
              style: context.textTheme.bodyMedium
                  ?.copyWith(color: WorkerColors.error)),
        ),
        data: (_) => Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              WorkerSizes.pagePadding,
              16,
              WorkerSizes.pagePadding,
              48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Profile photo
                _SectionCard(
                  title: 'Profile Photo',
                  child: _ProfilePhotoSection(
                    pickedImage: _pickedImage,
                    photoUrl: photoUrl,
                    onTap: _pickImage,
                  ),
                ),
                const SizedBox(height: WorkerSizes.sectionSpacing),

                // 2. Personal info
                _SectionCard(
                  title: 'Personal Information',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Full Name'),
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                            hintText: 'Enter your full name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('Phone Number'),
                      TextFormField(
                        initialValue: phoneNumber,
                        readOnly: true,
                        decoration: const InputDecoration(
                          suffixIcon: Icon(Icons.verified,
                              color: WorkerColors.success, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('CNIC'),
                      TextFormField(
                        controller: _cnicCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            hintText: 'XXXXX-XXXXXXX-X'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'CNIC is required';
                          }
                          final d = v.replaceAll(RegExp(r'\D'), '');
                          if (d.length != 13) {
                            return 'Enter a valid 13-digit CNIC';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WorkerSizes.sectionSpacing),

                // 3. Service info
                _SectionCard(
                  title: 'Service Information',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Service Type'),
                      DropdownButtonFormField<String>(
                        value: _serviceTypes.contains(_serviceType)
                            ? _serviceType
                            : null,
                        hint: const Text('Select service type'),
                        isExpanded: true,
                        items: _serviceTypes
                            .map((s) => DropdownMenuItem(
                                value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _serviceType = v),
                        validator: (v) => v == null
                            ? 'Please select a service type'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('Specializations'),
                      _SpecializationsField(
                        specializations: _specializations,
                        onChanged: (updated) => setState(
                            () => _specializations = updated),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('Hourly Rate'),
                      TextFormField(
                        controller: _hourlyRateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixText: 'PKR  ',
                          hintText: '500',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Hourly rate is required';
                          }
                          if (double.tryParse(v.trim()) == null) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WorkerSizes.sectionSpacing),

                // 4. Location
                _SectionCard(
                  title: 'Location',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('City'),
                      DropdownButtonFormField<String>(
                        value: _cities.contains(_city) ? _city : null,
                        hint: const Text('Select city'),
                        isExpanded: true,
                        items: _cities
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _city = v ?? ''),
                        validator: (v) =>
                            (v == null || v.isEmpty)
                                ? 'Please select a city'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('Service Zones'),
                      _ZoneMultiSelect(
                        zones: _zones,
                        selected: _selectedZones,
                        onChanged: (updated) =>
                            setState(() => _selectedZones = updated),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: WorkerSizes.minTouchTarget,
                        child: OutlinedButton.icon(
                          onPressed: _isUpdatingGps
                              ? null
                              : _updateGpsLocation,
                          icon: _isUpdatingGps
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.gps_fixed),
                          label: const Text('Update GPS Location'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WorkerSizes.sectionSpacing),

                // 5. Availability
                _SectionCard(
                  title: 'Availability',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Buffer Between Jobs'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [15, 30, 45, 60].map((mins) {
                          final selected = _bufferMinutes == mins;
                          return GestureDetector(
                            onTap: () => setState(
                                () => _bufferMinutes = mins),
                            child: Container(
                              width: 62,
                              height: WorkerSizes.minTouchTarget,
                              decoration: BoxDecoration(
                                color: selected
                                    ? WorkerColors.accent
                                    : WorkerColors.accentLight,
                                borderRadius: BorderRadius.circular(
                                    WorkerSizes.buttonRadius),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${mins}m',
                                style: context.textTheme.labelMedium
                                    ?.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : WorkerColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Vacation Mode',
                              style: context.textTheme.titleSmall),
                          Switch(
                            value: _vacationMode,
                            onChanged: (v) =>
                                setState(() => _vacationMode = v),
                          ),
                        ],
                      ),
                      if (_vacationMode) ...[
                        const SizedBox(height: 12),
                        _DateRangePickerRow(
                          startDate: _vacationStart,
                          endDate: _vacationEnd,
                          onStartTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate:
                                  _vacationStart ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (d != null && mounted) {
                              setState(() => _vacationStart = d);
                            }
                          },
                          onEndTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _vacationEnd ??
                                  (_vacationStart ??
                                          DateTime.now())
                                      .add(const Duration(days: 1)),
                              firstDate:
                                  _vacationStart ?? DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (d != null && mounted) {
                              setState(() => _vacationEnd = d);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: WorkerSizes.sectionSpacing),

                // 6. Payout
                _SectionCard(
                  title: 'Payout Settings',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Payment Method'),
                      ..._payoutMethods.map((method) {
                        return RadioListTile<String>(
                          title: Text(method),
                          value: method,
                          groupValue: _payoutMethod,
                          activeColor: WorkerColors.accent,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onChanged: (v) =>
                              setState(() => _payoutMethod = v!),
                        );
                      }),
                      const SizedBox(height: 12),
                      _FieldLabel('Account Number'),
                      TextFormField(
                        controller: _accountCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: _payoutMethod == 'Bank'
                              ? 'Enter IBAN or account number'
                              : 'Enter mobile account number',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Account number is required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: WorkerColors.successLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline,
                                size: 16,
                                color: WorkerColors.success),
                            const SizedBox(width: 8),
                            Text(
                              'Accounts are encrypted and secure',
                              style: context.textTheme.bodySmall
                                  ?.copyWith(
                                color: WorkerColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WorkerSizes.sectionSpacing),

                // 7. App info
                _SectionCard(
                  title: 'App Information',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Version',
                              style: context.textTheme.bodyMedium),
                          Text('1.0.0',
                              style: context.textTheme.bodyMedium
                                  ?.copyWith(
                                      color: WorkerColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: WorkerSizes.minTouchTarget,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: WorkerColors.error,
                            side: const BorderSide(
                                color: WorkerColors.error),
                          ),
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile photo section
// ---------------------------------------------------------------------------

class _ProfilePhotoSection extends StatelessWidget {
  const _ProfilePhotoSection({
    required this.pickedImage,
    required this.photoUrl,
    required this.onTap,
  });

  final File? pickedImage;
  final String photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            CircleAvatar(
              radius: WorkerSizes.avatarLg / 2,
              backgroundColor: WorkerColors.accentLight,
              backgroundImage: pickedImage != null
                  ? FileImage(pickedImage!) as ImageProvider
                  : (photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl) as ImageProvider
                      : null),
              child: (pickedImage == null && photoUrl.isEmpty)
                  ? const Icon(Icons.person,
                      size: 48, color: WorkerColors.textMuted)
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
                child: const Icon(Icons.edit,
                    size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorkerSizes.cardPadding),
      decoration: BoxDecoration(
        color: WorkerColors.surface,
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        boxShadow: WorkerColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.textTheme.titleLarge),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: context.textTheme.labelMedium
            ?.copyWith(color: WorkerColors.textMuted),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Specializations field
// ---------------------------------------------------------------------------

class _SpecializationsField extends StatefulWidget {
  const _SpecializationsField({
    required this.specializations,
    required this.onChanged,
  });

  final List<String> specializations;
  final void Function(List<String>) onChanged;

  @override
  State<_SpecializationsField> createState() =>
      _SpecializationsFieldState();
}

class _SpecializationsFieldState
    extends State<_SpecializationsField> {
  late List<String> _items;
  final _addCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.specializations);
  }

  @override
  void didUpdateWidget(_SpecializationsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.specializations != widget.specializations) {
      _items = List<String>.from(widget.specializations);
    }
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  void _addItem(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty || _items.contains(trimmed)) return;
    setState(() => _items.add(trimmed));
    _addCtrl.clear();
    widget.onChanged(_items);
  }

  void _removeItem(String item) {
    setState(() => _items.remove(item));
    widget.onChanged(_items);
  }

  Future<void> _showAddDialog(BuildContext context) async {
    _addCtrl.clear();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Specialization'),
        content: TextField(
          controller: _addCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
              hintText: 'e.g. Water Heater Repair'),
          onSubmitted: (v) {
            _addItem(v);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addItem(_addCtrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._items.map(
          (item) => Chip(
            label: Text(item),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () => _removeItem(item),
          ),
        ),
        GestureDetector(
          onTap: () => _showAddDialog(context),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                  color: WorkerColors.accent, width: 1.5),
              borderRadius:
                  BorderRadius.circular(WorkerSizes.chipRadius),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add,
                    size: 14, color: WorkerColors.accent),
                const SizedBox(width: 4),
                Text(
                  'Add',
                  style: context.textTheme.labelSmall
                      ?.copyWith(color: WorkerColors.accent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Zone multi-select
// ---------------------------------------------------------------------------

class _ZoneMultiSelect extends StatelessWidget {
  const _ZoneMultiSelect({
    required this.zones,
    required this.selected,
    required this.onChanged,
  });

  final List<String> zones;
  final List<String> selected;
  final void Function(List<String>) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: zones.map((zone) {
        final isSelected = selected.contains(zone);
        return GestureDetector(
          onTap: () {
            final updated = List<String>.from(selected);
            isSelected
                ? updated.remove(zone)
                : updated.add(zone);
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 36,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            decoration: BoxDecoration(
              color: isSelected
                  ? WorkerColors.accent
                  : WorkerColors.accentLight,
              borderRadius:
                  BorderRadius.circular(WorkerSizes.chipRadius),
            ),
            alignment: Alignment.center,
            child: Text(
              zone,
              style: context.textTheme.labelSmall?.copyWith(
                color: isSelected ? Colors.white : WorkerColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Date range picker row
// ---------------------------------------------------------------------------

class _DateRangePickerRow extends StatelessWidget {
  const _DateRangePickerRow({
    required this.startDate,
    required this.endDate,
    required this.onStartTap,
    required this.onEndTap,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  String _fmt(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateButton(
              label: 'From',
              value: _fmt(startDate),
              onTap: onStartTap),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateButton(
              label: 'To',
              value: _fmt(endDate),
              onTap: onEndTap),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: WorkerSizes.minTouchTarget,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: WorkerColors.divider),
          borderRadius: BorderRadius.circular(WorkerSizes.inputRadius),
          color: WorkerColors.surface,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: WorkerColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: context.textTheme.labelSmall),
                  Text(
                    value,
                    style: context.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
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
