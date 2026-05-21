class SavedAddress {
  final String id;
  final String label;
  final String street;
  final String city;
  final String zone;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.zone,
    this.isDefault = false,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> j) => SavedAddress(
        id: j['id'] as String,
        label: j['label'] as String? ?? 'Other',
        street: j['street'] as String? ?? '',
        city: j['city'] as String? ?? '',
        zone: j['zone'] as String? ?? '',
        isDefault: j['isDefault'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'street': street,
        'city': city,
        'zone': zone,
        'isDefault': isDefault,
      };
}
