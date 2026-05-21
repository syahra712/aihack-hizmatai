import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String bookingRef;
  final String customerName;
  final double rating;
  final String reviewText;
  final DateTime createdAt;
  final String? workerReply;

  const Review({
    required this.bookingRef,
    required this.customerName,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
    this.workerReply,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Review(
      bookingRef: doc.id,
      customerName: d['customer_name'] as String? ?? 'Customer',
      rating: (d['customer_rating'] as num?)?.toDouble() ?? 0.0,
      reviewText: d['customer_review'] as String? ?? '',
      createdAt: d['created_at'] is Timestamp
          ? (d['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      workerReply: d['worker_reply'] as String?,
    );
  }
}
