class HizmatUser {
  final String uid;
  final String name;
  final String city;
  final String? phone;
  final String? profilePhotoUrl;
  final DateTime createdAt;

  const HizmatUser({
    required this.uid,
    required this.name,
    required this.city,
    this.phone,
    this.profilePhotoUrl,
    required this.createdAt,
  });

  factory HizmatUser.fromJson(Map<String, dynamic> j) => HizmatUser(
        uid: j['uid'] as String,
        name: j['name'] as String? ?? '',
        city: j['city'] as String? ?? '',
        phone: j['phone'] as String?,
        profilePhotoUrl: j['profilePhotoUrl'] as String?,
        createdAt: (j['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'city': city,
        if (phone != null) 'phone': phone,
        if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
        'createdAt': createdAt,
      };

  HizmatUser copyWith({
    String? name,
    String? city,
    String? phone,
    String? profilePhotoUrl,
  }) =>
      HizmatUser(
        uid: uid,
        name: name ?? this.name,
        city: city ?? this.city,
        phone: phone ?? this.phone,
        profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
        createdAt: createdAt,
      );
}
