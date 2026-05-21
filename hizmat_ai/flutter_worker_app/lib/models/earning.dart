import 'package:cloud_firestore/cloud_firestore.dart';

enum EarningStatus {
  pending,
  cleared,
  disputed,
  paidOut;

  static EarningStatus fromString(String value) {
    switch (value) {
      case 'cleared':
        return EarningStatus.cleared;
      case 'disputed':
        return EarningStatus.disputed;
      case 'paid_out':
        return EarningStatus.paidOut;
      default:
        return EarningStatus.pending;
    }
  }

  String toFirestoreString() {
    switch (this) {
      case EarningStatus.pending:
        return 'pending';
      case EarningStatus.cleared:
        return 'cleared';
      case EarningStatus.disputed:
        return 'disputed';
      case EarningStatus.paidOut:
        return 'paid_out';
    }
  }

  String get displayLabel {
    switch (this) {
      case EarningStatus.pending:
        return 'Pending';
      case EarningStatus.cleared:
        return 'Cleared';
      case EarningStatus.disputed:
        return 'Disputed';
      case EarningStatus.paidOut:
        return 'Paid Out';
    }
  }
}

class Earning {
  final String id;
  final String workerId;
  final String bookingRef;
  final String serviceType;
  final double grossAmount;
  final double platformFee;
  final double netAmount;
  final EarningStatus status;
  final DateTime? clearedAt;
  final String payoutRef;
  final DateTime? createdAt;

  const Earning({
    required this.id,
    required this.workerId,
    required this.bookingRef,
    required this.serviceType,
    required this.grossAmount,
    required this.platformFee,
    required this.netAmount,
    this.status = EarningStatus.pending,
    this.clearedAt,
    this.payoutRef = '',
    this.createdAt,
  });

  static DateTime? _ts(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  factory Earning.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Earning(
      id: doc.id,
      workerId: d['worker_id'] as String? ?? '',
      bookingRef: d['booking_ref'] as String? ?? '',
      serviceType: d['service_type'] as String? ?? '',
      grossAmount: (d['gross_amount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (d['platform_fee'] as num?)?.toDouble() ?? 0.0,
      netAmount: (d['net_amount'] as num?)?.toDouble() ?? 0.0,
      status: EarningStatus.fromString(d['status'] as String? ?? ''),
      clearedAt: _ts(d['cleared_at']),
      payoutRef: d['payout_ref'] as String? ?? '',
      createdAt: _ts(d['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
        'worker_id': workerId,
        'booking_ref': bookingRef,
        'service_type': serviceType,
        'gross_amount': grossAmount,
        'platform_fee': platformFee,
        'net_amount': netAmount,
        'status': status.toFirestoreString(),
        'cleared_at': clearedAt != null ? Timestamp.fromDate(clearedAt!) : null,
        'payout_ref': payoutRef,
        'created_at':
            createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };
}
