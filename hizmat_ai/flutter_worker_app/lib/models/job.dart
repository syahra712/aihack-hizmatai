import 'package:cloud_firestore/cloud_firestore.dart';

enum JobStatus {
  pendingWorker,
  confirmed,
  enRoute,
  arrived,
  inProgress,
  completed,
  cancelled,
  disputed;

  static JobStatus fromString(String value) {
    switch (value) {
      case 'pending_worker':
        return JobStatus.pendingWorker;
      case 'confirmed':
        return JobStatus.confirmed;
      case 'en_route':
        return JobStatus.enRoute;
      case 'arrived':
        return JobStatus.arrived;
      case 'in_progress':
        return JobStatus.inProgress;
      case 'completed':
        return JobStatus.completed;
      case 'cancelled':
        return JobStatus.cancelled;
      case 'disputed':
        return JobStatus.disputed;
      default:
        return JobStatus.pendingWorker;
    }
  }

  String toFirestoreString() {
    switch (this) {
      case JobStatus.pendingWorker:
        return 'pending_worker';
      case JobStatus.confirmed:
        return 'confirmed';
      case JobStatus.enRoute:
        return 'en_route';
      case JobStatus.arrived:
        return 'arrived';
      case JobStatus.inProgress:
        return 'in_progress';
      case JobStatus.completed:
        return 'completed';
      case JobStatus.cancelled:
        return 'cancelled';
      case JobStatus.disputed:
        return 'disputed';
    }
  }

  String get displayLabel {
    switch (this) {
      case JobStatus.pendingWorker:
        return 'Pending';
      case JobStatus.confirmed:
        return 'Confirmed';
      case JobStatus.enRoute:
        return 'En Route';
      case JobStatus.arrived:
        return 'Arrived';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
      case JobStatus.disputed:
        return 'Disputed';
    }
  }
}

class Job {
  final String ref;
  final String customerId;
  final String customerName;
  final String providerId;
  final String providerName;
  final String serviceType;
  final String city;
  final String zone;

  // Location
  final double customerLat;
  final double customerLng;
  final String customerAddress;
  final double distanceKm;

  // Timing
  final DateTime slot;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  // Status
  final JobStatus status;

  // Pricing
  final Map<String, dynamic> priceBreakdown;
  final double? actualHours;
  final List<Map<String, dynamic>> extraWork;
  final double? finalPrice;

  // Payment
  final String paymentStatus;
  final String stripePaymentIntentId;

  // Photos
  final List<String> photosBefore;
  final List<String> photosAfter;

  // Timeline
  final List<Map<String, dynamic>> timeline;

  // Assignment
  final List<Map<String, dynamic>> declinedBy;
  final int assignmentAttempts;

  // Reviews
  final double? customerRating;
  final String customerReview;
  final String workerReply;
  final Map<String, dynamic>? dispute;

  // Meta
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isUrgent;
  final String language;

  const Job({
    required this.ref,
    required this.customerId,
    required this.customerName,
    required this.providerId,
    required this.providerName,
    required this.serviceType,
    required this.city,
    required this.zone,
    required this.customerLat,
    required this.customerLng,
    required this.customerAddress,
    required this.distanceKm,
    required this.slot,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    required this.status,
    required this.priceBreakdown,
    this.actualHours,
    this.extraWork = const [],
    this.finalPrice,
    required this.paymentStatus,
    required this.stripePaymentIntentId,
    this.photosBefore = const [],
    this.photosAfter = const [],
    this.timeline = const [],
    this.declinedBy = const [],
    required this.assignmentAttempts,
    this.customerRating,
    this.customerReview = '',
    this.workerReply = '',
    this.dispute,
    this.createdAt,
    this.updatedAt,
    required this.isUrgent,
    required this.language,
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

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value == null) return [];
    return List<Map<String, dynamic>>.from(
      (value as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  factory Job.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Job(
      ref: doc.id,
      customerId: d['customer_id'] as String? ?? '',
      customerName: d['customer_name'] as String? ?? '',
      providerId: d['provider_id'] as String? ?? '',
      providerName: d['provider_name'] as String? ?? '',
      serviceType: d['service_type'] as String? ?? '',
      city: d['city'] as String? ?? '',
      zone: d['zone'] as String? ?? '',
      customerLat: (d['customer_lat'] as num?)?.toDouble() ?? 0.0,
      customerLng: (d['customer_lng'] as num?)?.toDouble() ?? 0.0,
      customerAddress: d['customer_address'] as String? ?? '',
      distanceKm: (d['distance_km'] as num?)?.toDouble() ?? 0.0,
      slot: _ts(d['slot']) ?? DateTime.now(),
      acceptedAt: _ts(d['accepted_at']),
      arrivedAt: _ts(d['arrived_at']),
      startedAt: _ts(d['started_at']),
      completedAt: _ts(d['completed_at']),
      cancelledAt: _ts(d['cancelled_at']),
      status: JobStatus.fromString(d['status'] as String? ?? ''),
      priceBreakdown: d['price_breakdown'] != null
          ? Map<String, dynamic>.from(d['price_breakdown'] as Map)
          : {},
      actualHours: (d['actual_hours'] as num?)?.toDouble(),
      extraWork: _maps(d['extra_work']),
      finalPrice: (d['final_price'] as num?)?.toDouble(),
      paymentStatus: d['payment_status'] as String? ?? '',
      stripePaymentIntentId: d['stripe_payment_intent_id'] as String? ?? '',
      photosBefore: _strings(d['photos_before']),
      photosAfter: _strings(d['photos_after']),
      timeline: _maps(d['timeline']),
      declinedBy: _maps(d['declined_by']),
      assignmentAttempts: d['assignment_attempts'] as int? ?? 0,
      customerRating: (d['customer_rating'] as num?)?.toDouble(),
      customerReview: d['customer_review'] as String? ?? '',
      workerReply: d['worker_reply'] as String? ?? '',
      dispute: d['dispute'] != null
          ? Map<String, dynamic>.from(d['dispute'] as Map)
          : null,
      createdAt: _ts(d['created_at']),
      updatedAt: _ts(d['updated_at']),
      isUrgent: d['is_urgent'] as bool? ?? false,
      language: d['language'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'provider_id': providerId,
      'provider_name': providerName,
      'service_type': serviceType,
      'city': city,
      'zone': zone,
      'customer_lat': customerLat,
      'customer_lng': customerLng,
      'customer_address': customerAddress,
      'distance_km': distanceKm,
      'slot': Timestamp.fromDate(slot),
      'accepted_at': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'arrived_at': arrivedAt != null ? Timestamp.fromDate(arrivedAt!) : null,
      'started_at': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completed_at':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelled_at':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'status': status.toFirestoreString(),
      'price_breakdown': priceBreakdown,
      'actual_hours': actualHours,
      'extra_work': extraWork,
      'final_price': finalPrice,
      'payment_status': paymentStatus,
      'stripe_payment_intent_id': stripePaymentIntentId,
      'photos_before': photosBefore,
      'photos_after': photosAfter,
      'timeline': timeline,
      'declined_by': declinedBy,
      'assignment_attempts': assignmentAttempts,
      'customer_rating': customerRating,
      'customer_review': customerReview,
      'worker_reply': workerReply,
      'dispute': dispute,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'is_urgent': isUrgent,
      'language': language,
    };
  }

  bool get isActive =>
      status == JobStatus.enRoute ||
      status == JobStatus.arrived ||
      status == JobStatus.inProgress;

  bool get isPending => status == JobStatus.pendingWorker;
  bool get isCompleted => status == JobStatus.completed;
  bool get isCancelled => status == JobStatus.cancelled;

  String get serviceLabel => {
        'electrician': 'Electrician',
        'plumber': 'Plumber',
        'cleaner': 'Cleaner',
        'cleaning': 'Cleaning',
        'ac_repair': 'AC Technician',
        'home_tutor': 'Home Tutor',
        'beautician': 'Beautician',
        'painter': 'Painter',
        'carpenter': 'Carpenter',
      }[serviceType] ??
      serviceType;
}
