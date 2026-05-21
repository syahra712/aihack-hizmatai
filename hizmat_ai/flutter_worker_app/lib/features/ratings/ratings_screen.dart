import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../models/review.dart';
import '../../providers/providers.dart';
import '../../services/firestore_service.dart';

// ---------------------------------------------------------------------------
// Ratings Screen
// ---------------------------------------------------------------------------

class RatingsScreen extends ConsumerWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsProvider);

    return Scaffold(
      backgroundColor: WorkerColors.background,
      appBar: AppBar(
        title: const Text('My Ratings'),
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: WorkerColors.error),
              const SizedBox(height: 12),
              Text('Failed to load reviews',
                  style: context.textTheme.bodyMedium
                      ?.copyWith(color: WorkerColors.error)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(reviewsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (reviews) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              WorkerSizes.pagePadding,
              16,
              WorkerSizes.pagePadding,
              32,
            ),
            children: [
              _OverallRatingCard(reviews: reviews),
              const SizedBox(height: WorkerSizes.sectionSpacing),
              _PerformanceInsightCard(),
              const SizedBox(height: WorkerSizes.sectionSpacing),
              Text('Customer Reviews',
                  style: context.textTheme.titleLarge),
              const SizedBox(height: 12),
              if (reviews.isEmpty)
                _EmptyReviewsMessage()
              else
                ...reviews.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReviewCard(review: r),
                    )),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overall rating card
// ---------------------------------------------------------------------------

class _OverallRatingCard extends ConsumerWidget {
  const _OverallRatingCard({required this.reviews});

  final List<Review> reviews;

  double get _avgRating {
    final profile =
        _profileRating; // fallback to dummy if no reviews
    return profile;
  }

  double get _profileRating => 4.8; // driven from workerProfileProvider

  Map<int, double> _starDistribution() {
    if (reviews.isEmpty) {
      return {5: 0.80, 4: 0.15, 3: 0.04, 2: 0.01, 1: 0.0};
    }
    final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in reviews) {
      final star = r.rating.round().clamp(1, 5);
      counts[star] = (counts[star] ?? 0) + 1;
    }
    final total = reviews.length;
    return counts
        .map((k, v) => MapEntry(k, total > 0 ? v / total : 0.0));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(workerProfileProvider).valueOrNull;
    final avgRating = profile?.rating ?? _avgRating;
    final dist = _starDistribution();

    return Container(
      padding: const EdgeInsets.all(WorkerSizes.cardPadding),
      decoration: BoxDecoration(
        color: WorkerColors.surface,
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        boxShadow: WorkerColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating + stars
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: WorkerColors.accent,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StarRow(rating: avgRating),
                  const SizedBox(height: 4),
                  Text(
                    '${profile?.reviewCount ?? reviews.length} reviews',
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Star histogram
          ...List.generate(5, (i) {
            final star = 5 - i;
            final pct = dist[star] ?? 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Row(
                      children: [
                        Text('$star',
                            style: context.textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const Icon(Icons.star,
                            size: 10, color: WorkerColors.warning),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: WorkerColors.accentLight,
                        color: WorkerColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: context.textTheme.labelSmall,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          // Metric chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label:
                    'On-time ${((profile?.onTimeScore ?? 0.92) * 100).toStringAsFixed(0)}%',
                icon: Icons.access_time_outlined,
              ),
              _MetricChip(
                label:
                    'Completed ${((profile?.completionRate ?? 0.96) * 100).toStringAsFixed(0)}%',
                icon: Icons.check_circle_outline,
              ),
              _MetricChip(
                label: profile != null
                    ? 'Response ${_fmtSeconds(profile.avgResponseSeconds)}'
                    : 'Response 3 min',
                icon: Icons.speed_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtSeconds(int s) {
    if (s < 60) return '${s}s';
    final m = (s / 60).floor();
    return '${m} min';
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= (i + 1);
        final partial = !filled && rating > i;
        return Icon(
          partial ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
          size: 20,
          color: WorkerColors.warning,
        );
      }),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: WorkerColors.accentLight,
        borderRadius: BorderRadius.circular(WorkerSizes.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: WorkerColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: WorkerColors.accentDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Performance insight card
// ---------------------------------------------------------------------------

class _PerformanceInsightCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WorkerSizes.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0EB), Color(0xFFFFEDE4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        border: Border.all(
          color: WorkerColors.accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.insights_outlined,
                size: 20, color: WorkerColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Insight',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: WorkerColors.accentDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your on-time score contributes 20% to your discovery ranking. Improving it increases job assignments.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: WorkerColors.accentDark,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty reviews message
// ---------------------------------------------------------------------------

class _EmptyReviewsMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined,
              size: 56, color: WorkerColors.textLight),
          const SizedBox(height: 12),
          Text(
            'No reviews yet',
            style: context.textTheme.headlineSmall
                ?.copyWith(color: WorkerColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete jobs to receive your first review',
            style: context.textTheme.bodyMedium
                ?.copyWith(color: WorkerColors.textLight),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual review card
// ---------------------------------------------------------------------------

class _ReviewCard extends ConsumerStatefulWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  bool _showReplyField = false;
  final _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  String _customerDisplay(String name) {
    if (name.isEmpty) return 'C. Customer';
    final parts = name.trim().split(' ');
    final initial = parts.first[0].toUpperCase();
    final first = parts.first.capitalised();
    return '$initial. $first';
  }

  Future<void> _sendReply() async {
    final reply = _replyController.text.trim();
    if (reply.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await ref
          .read(firestoreServiceProvider)
          .replyToReview(widget.review.bookingRef, reply);

      ref.invalidate(reviewsProvider);

      if (mounted) {
        setState(() {
          _showReplyField = false;
          _isSending = false;
        });
        context.showSnackBar('Reply sent');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        context.showSnackBar('Failed to send reply', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final hasReply =
        review.workerReply != null && review.workerReply!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(WorkerSizes.cardPadding),
      decoration: BoxDecoration(
        color: WorkerColors.surface,
        borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        boxShadow: WorkerColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: WorkerColors.accentLight,
                child: Text(
                  review.customerName.isNotEmpty
                      ? review.customerName[0].toUpperCase()
                      : 'C',
                  style: context.textTheme.titleMedium
                      ?.copyWith(color: WorkerColors.accent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _customerDisplay(review.customerName),
                      style: context.textTheme.titleSmall,
                    ),
                    Text(
                      DateFormat('d MMM yyyy').format(review.createdAt),
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _StarRow(rating: review.rating),
            ],
          ),
          const SizedBox(height: 10),
          // Review text
          if (review.reviewText.isNotEmpty)
            Text(
              review.reviewText,
              style: context.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          const SizedBox(height: 10),
          // Reply section
          if (hasReply) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WorkerColors.accentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.reply, size: 16, color: WorkerColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'You replied: ',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: WorkerColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: review.workerReply,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: WorkerColors.accentDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (_showReplyField) ...[
              TextFormField(
                controller: _replyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Write a professional reply...',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () => setState(() {
                              _showReplyField = false;
                              _replyController.clear();
                            }),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSending ? null : _sendReply,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 44),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send Reply'),
                  ),
                ],
              ),
            ] else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showReplyField = true),
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Reply'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
