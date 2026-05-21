import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerProfile {
  final String id;
  final String uid;
  final String name;
  final String phone;
  final String cnic;
  final String profilePhotoUrl;

  // Service details
  final String serviceType;
  final List<String> specializations;
  final double hourlyRate;
  final List<String> certifications;

  // Location
  final String city;
  final String zone;
  final double lat;
  final double lng;
  final DateTime? lastLocationUpdate;

  // Availability
  final bool isAvailable;
  final bool isOnJob;
  final bool vacationMode;
  final DateTime? vacationStart;
  final DateTime? vacationEnd;
  final List<String> availableSlots;
  final int bufferMinutes;

  // Performance metrics
  final double rating;
  final int reviewCount;
  final int totalJobs;
  final double onTimeScore;
  final double cancellationRate;
  final double completionRate;
  final int avgResponseSeconds;

  // Payout
  final String payoutMethod;
  final String payoutAccount;

  // Meta
  final DateTime? registeredAt;
  final DateTime? lastActive;
  final String appVersion;
  final bool isVerified;
  final bool isSuspended;

  const WorkerProfile({
    required this.id,
    required this.uid,
    required this.name,
    required this.phone,
    required this.cnic,
    required this.profilePhotoUrl,
    required this.serviceType,
    required this.specializations,
    required this.hourlyRate,
    required this.certifications,
    required this.city,
    required this.zone,
    required this.lat,
    required this.lng,
    this.lastLocationUpdate,
    required this.isAvailable,
    required this.isOnJob,
    required this.vacationMode,
    this.vacationStart,
    this.vacationEnd,
    required this.availableSlots,
    required this.bufferMinutes,
    required this.rating,
    required this.reviewCount,
    required this.totalJobs,
    required this.onTimeScore,
    required this.cancellationRate,
    required this.completionRate,
    required this.avgResponseSeconds,
    required this.payoutMethod,
    required this.payoutAccount,
    this.registeredAt,
    this.lastActive,
    required this.appVersion,
    required this.isVerified,
    required this.isSuspended,
  });

  static DateTime? _ts(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static List<String> _strings(dynamic value) {
    if (value == null) return [];
    return List<String>.from(value as List);
  }

  factory WorkerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkerProfile(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      cnic: data['cnic'] as String? ?? '',
      profilePhotoUrl: data['profile_photo_url'] as String? ?? '',
      serviceType: data['service_type'] as String? ?? '',
      specializations: _strings(data['specializations']),
      hourlyRate: (data['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      certifications: _strings(data['certifications']),
      city: data['city'] as String? ?? '',
      zone: data['zone'] as String? ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      lastLocationUpdate: _ts(data['last_location_update']),
      isAvailable: data['is_available'] as bool? ?? false,
      isOnJob: data['is_on_job'] as bool? ?? false,
      vacationMode: data['vacation_mode'] as bool? ?? false,
      vacationStart: _ts(data['vacation_start']),
      vacationEnd: _ts(data['vacation_end']),
      availableSlots: _strings(data['available_slots']),
      bufferMinutes: data['buffer_minutes'] as int? ?? 15,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['review_count'] as int? ?? 0,
      totalJobs: data['total_jobs'] as int? ?? 0,
      onTimeScore: (data['on_time_score'] as num?)?.toDouble() ?? 0.0,
      cancellationRate: (data['cancellation_rate'] as num?)?.toDouble() ?? 0.0,
      completionRate: (data['completion_rate'] as num?)?.toDouble() ?? 0.0,
      avgResponseSeconds: data['avg_response_seconds'] as int? ?? 0,
      payoutMethod: data['payout_method'] as String? ?? '',
      payoutAccount: data['payout_account'] as String? ?? '',
      registeredAt: _ts(data['registered_at']),
      lastActive: _ts(data['last_active']),
      appVersion: data['app_version'] as String? ?? '',
      isVerified: data['is_verified'] as bool? ?? false,
      isSuspended: data['is_suspended'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'cnic': cnic,
      'profile_photo_url': profilePhotoUrl,
      'service_type': serviceType,
      'specializations': specializations,
      'hourly_rate': hourlyRate,
      'certifications': certifications,
      'city': city,
      'zone': zone,
      'lat': lat,
      'lng': lng,
      'last_location_update':
          lastLocationUpdate != null ? Timestamp.fromDate(lastLocationUpdate!) : null,
      'is_available': isAvailable,
      'is_on_job': isOnJob,
      'vacation_mode': vacationMode,
      'vacation_start':
          vacationStart != null ? Timestamp.fromDate(vacationStart!) : null,
      'vacation_end':
          vacationEnd != null ? Timestamp.fromDate(vacationEnd!) : null,
      'available_slots': availableSlots,
      'buffer_minutes': bufferMinutes,
      'rating': rating,
      'review_count': reviewCount,
      'total_jobs': totalJobs,
      'on_time_score': onTimeScore,
      'cancellation_rate': cancellationRate,
      'completion_rate': completionRate,
      'avg_response_seconds': avgResponseSeconds,
      'payout_method': payoutMethod,
      'payout_account': payoutAccount,
      'registered_at':
          registeredAt != null ? Timestamp.fromDate(registeredAt!) : null,
      'last_active':
          lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'app_version': appVersion,
      'is_verified': isVerified,
      'is_suspended': isSuspended,
    };
  }

  WorkerProfile copyWith({
    String? id,
    String? uid,
    String? name,
    String? phone,
    String? cnic,
    String? profilePhotoUrl,
    String? serviceType,
    List<String>? specializations,
    double? hourlyRate,
    List<String>? certifications,
    String? city,
    String? zone,
    double? lat,
    double? lng,
    DateTime? lastLocationUpdate,
    bool? isAvailable,
    bool? isOnJob,
    bool? vacationMode,
    DateTime? vacationStart,
    DateTime? vacationEnd,
    List<String>? availableSlots,
    int? bufferMinutes,
    double? rating,
    int? reviewCount,
    int? totalJobs,
    double? onTimeScore,
    double? cancellationRate,
    double? completionRate,
    int? avgResponseSeconds,
    String? payoutMethod,
    String? payoutAccount,
    DateTime? registeredAt,
    DateTime? lastActive,
    String? appVersion,
    bool? isVerified,
    bool? isSuspended,
  }) {
    return WorkerProfile(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      cnic: cnic ?? this.cnic,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      serviceType: serviceType ?? this.serviceType,
      specializations: specializations ?? this.specializations,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      certifications: certifications ?? this.certifications,
      city: city ?? this.city,
      zone: zone ?? this.zone,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      isAvailable: isAvailable ?? this.isAvailable,
      isOnJob: isOnJob ?? this.isOnJob,
      vacationMode: vacationMode ?? this.vacationMode,
      vacationStart: vacationStart ?? this.vacationStart,
      vacationEnd: vacationEnd ?? this.vacationEnd,
      availableSlots: availableSlots ?? this.availableSlots,
      bufferMinutes: bufferMinutes ?? this.bufferMinutes,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      totalJobs: totalJobs ?? this.totalJobs,
      onTimeScore: onTimeScore ?? this.onTimeScore,
      cancellationRate: cancellationRate ?? this.cancellationRate,
      completionRate: completionRate ?? this.completionRate,
      avgResponseSeconds: avgResponseSeconds ?? this.avgResponseSeconds,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      payoutAccount: payoutAccount ?? this.payoutAccount,
      registeredAt: registeredAt ?? this.registeredAt,
      lastActive: lastActive ?? this.lastActive,
      appVersion: appVersion ?? this.appVersion,
      isVerified: isVerified ?? this.isVerified,
      isSuspended: isSuspended ?? this.isSuspended,
    );
  }
}
