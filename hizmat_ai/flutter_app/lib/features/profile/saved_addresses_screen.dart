import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/address_model.dart';
import '../../services/firebase_service.dart';
import '../../services/user_service.dart';

class SavedAddressesScreen extends ConsumerStatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  ConsumerState<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends ConsumerState<SavedAddressesScreen> {
  List<SavedAddress> _addresses = [];
  bool _loading = true;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    _uid = user.uid;
    final addresses = await ref.read(userServiceProvider).getAddresses(user.uid);
    if (mounted) setState(() { _addresses = addresses; _loading = false; });
  }

  Future<void> _deleteAddress(String id) async {
    if (_uid == null) return;
    await ref.read(userServiceProvider).deleteAddress(_uid!, id);
    setState(() => _addresses.removeWhere((a) => a.id == id));
  }

  void _showAddSheet() {
    final labelCtrl = ValueNotifier<String>('Home');
    final streetCtrl = TextEditingController();
    final zoneCtrl = TextEditingController();
    String selectedCity = AppConstants.cities.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Address', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
                  const SizedBox(height: 20),
                  Text('Label', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String>(
                    valueListenable: labelCtrl,
                    builder: (_, label, __) => Row(
                      children: ['Home', 'Office', 'Other'].map((l) {
                        final selected = label == l;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(l, style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.text,
                            )),
                            selected: selected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceLight,
                            onSelected: (_) { labelCtrl.value = l; },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Street', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: streetCtrl,
                    style: GoogleFonts.poppins(fontSize: 15, color: AppColors.text),
                    decoration: const InputDecoration(hintText: 'e.g. Plot 5, Street 12, DHA'),
                  ),
                  const SizedBox(height: 16),
                  Text('City', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(16)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCity,
                        isExpanded: true,
                        style: GoogleFonts.poppins(fontSize: 15, color: AppColors.text),
                        dropdownColor: AppColors.surface,
                        items: AppConstants.cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) { if (v != null) setSheetState(() => selectedCity = v); },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Zone / Area', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: zoneCtrl,
                    style: GoogleFonts.poppins(fontSize: 15, color: AppColors.text),
                    decoration: const InputDecoration(hintText: 'e.g. Clifton Block 4'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final street = streetCtrl.text.trim();
                      final zone = zoneCtrl.text.trim();
                      if (street.isEmpty) return;
                      if (_uid == null) return;
                      final address = SavedAddress(
                        id: const Uuid().v4(),
                        label: labelCtrl.value,
                        street: street,
                        city: selectedCity,
                        zone: zone,
                      );
                      await ref.read(userServiceProvider).addAddress(_uid!, address);
                      if (ctx.mounted) Navigator.pop(ctx);
                      setState(() => _addresses = [..._addresses, address]);
                    },
                    child: Text('Save Address', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Saved Addresses', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.text)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Address', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_off_rounded, size: 56, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text('No saved addresses', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textMuted)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: _addresses.length,
                  itemBuilder: (_, i) {
                    final addr = _addresses[i];
                    return Dismissible(
                      key: Key(addr.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.delete_rounded, color: AppColors.error),
                      ),
                      onDismissed: (_) => _deleteAddress(addr.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                              child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(addr.label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(addr.street, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                                  Text('${addr.zone}, ${addr.city}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
