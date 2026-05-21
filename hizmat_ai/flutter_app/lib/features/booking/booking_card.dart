import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/booking.dart';
import 'live_tracker.dart';

class BookingCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onPay;
  final VoidCallback? onCancel;
  const BookingCard({super.key, required this.booking, this.onPay, this.onCancel});

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  bool _showTracker = false;
  bool _showCancelConfirm = false;

  Booking get booking => widget.booking;

  IconData get _serviceIcon => {
    'electrician': Icons.electrical_services_rounded,
    'plumber': Icons.plumbing_rounded,
    'cleaner': Icons.cleaning_services_rounded,
    'cleaning': Icons.cleaning_services_rounded,
    'ac_repair': Icons.ac_unit_rounded,
    'painter': Icons.format_paint_rounded,
    'carpenter': Icons.handyman_rounded,
    'home_tutor': Icons.school_rounded,
    'beautician': Icons.spa_rounded,
  }[booking.serviceType] ?? Icons.home_repair_service_rounded;

  String get _serviceEmoji => {
    'electrician': '⚡',
    'plumber': '🔧',
    'cleaner': '🧹',
    'cleaning': '🧹',
    'ac_repair': '❄️',
    'painter': '🎨',
    'carpenter': '🪚',
    'home_tutor': '📚',
    'beautician': '💅',
  }[booking.serviceType] ?? '🔨';

  Color get _statusColor => switch (booking.status) {
    BookingStatus.confirmed => AppColors.amber,
    BookingStatus.pending => AppColors.amber,
    BookingStatus.completed => const Color(0xFF059669),
    BookingStatus.cancelled => AppColors.error,
    BookingStatus.paid => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final isCancelled = booking.isCancelled;

    return Opacity(
      opacity: isCancelled ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.soft,
          border: booking.isPaid
              ? Border.all(color: AppColors.primary.withOpacity(0.15))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: emoji + provider info + status badge
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(_serviceEmoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.providerName,
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _statusColor.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _statusColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  booking.statusLabel.toUpperCase(),
                                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: _statusColor, letterSpacing: 0.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Meta info row
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(booking.city, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('dd MMM').format(booking.dateTime),
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                          ),
                          if (booking.dateTime.hour > 0) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.access_time_rounded, size: 11, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat('hh:mm a').format(booking.dateTime),
                              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Price + actions row
            Row(
              children: [
                Text(
                  'PKR ${_fmt(booking.estimatedCost)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isCancelled ? AppColors.textMuted : AppColors.primary,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                const Spacer(),
                if (booking.isPaid && booking.paidLast4 != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('Card ••${booking.paidLast4}', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                  ),
                if (booking.isPayable && widget.onPay != null)
                  GestureDetector(
                    onTap: widget.onPay,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00B894)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppShadows.primaryGlow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.credit_card_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text('Pay Now', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Booking ID
            const SizedBox(height: 6),
            Text(
              booking.id,
              style: GoogleFonts.sourceCodePro(fontSize: 10, color: AppColors.textMuted),
            ),

            // Action buttons row: Track / Cancel
            if (booking.isPaid || booking.isPayable) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (booking.isPaid)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showTracker = !_showTracker),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _showTracker ? AppColors.primary.withOpacity(0.08) : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: _showTracker ? Border.all(color: AppColors.primary.withOpacity(0.2)) : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _showTracker ? Icons.timeline_rounded : Icons.location_on_rounded,
                                size: 15,
                                color: _showTracker ? AppColors.primary : AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _showTracker ? 'Hide Tracker' : 'Track Live',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _showTracker ? AppColors.primary : AppColors.textMuted,
                                ),
                              ),
                              if (!_showTracker) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (booking.isPaid && booking.isPayable) const SizedBox(width: 8),
                  if (booking.isPayable && widget.onCancel != null)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showCancelConfirm = !_showCancelConfirm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _showCancelConfirm ? AppColors.error.withOpacity(0.06) : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel_outlined, size: 15, color: _showCancelConfirm ? AppColors.error : AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                'Cancel',
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _showCancelConfirm ? AppColors.error : AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],

            // Cancel confirmation inline
            if (_showCancelConfirm && booking.isPayable) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withOpacity(0.12)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text('Cancel this booking?', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _showCancelConfirm = false);
                              widget.onCancel?.call();
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Text('Yes, cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 12))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showCancelConfirm = false),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Text('Keep it', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0),
            ],

            // Live Tracker inline (paid bookings)
            if (_showTracker && booking.isPaid)
              LiveTracker(active: true, providerName: booking.providerName),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    return n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}
