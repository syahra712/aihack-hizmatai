import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import 'booking_card.dart';
import 'payment_sheet.dart';

enum _Filter { all, paid, unpaid, cancelled }

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  _Filter _filter = _Filter.all;

  List<Booking> _filtered(List<Booking> bookings) {
    return switch (_filter) {
      _Filter.all => bookings,
      _Filter.paid => bookings.where((b) => b.isPaid).toList(),
      _Filter.unpaid => bookings.where((b) => b.isPayable).toList(),
      _Filter.cancelled => bookings.where((b) => b.isCancelled).toList(),
    };
  }

  int _count(List<Booking> bookings, _Filter f) {
    return switch (f) {
      _Filter.all => bookings.length,
      _Filter.paid => bookings.where((b) => b.isPaid).length,
      _Filter.unpaid => bookings.where((b) => b.isPayable).length,
      _Filter.cancelled => bookings.where((b) => b.isCancelled).length,
    };
  }

  void _openPayment(Booking booking) {
    PaymentSheet.show(
      context,
      amount: booking.estimatedCost,
      providerName: booking.providerName,
      bookingId: booking.id,
      onSuccess: (result) {
        ref.read(bookingServiceProvider.notifier).markAsPaid(booking.id, last4: result.last4);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment confirmed! PKR ${booking.estimatedCost}', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(bookingServiceProvider);
    final filtered = _filtered(bookings);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text('Booking History', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.text)),
            if (bookings.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                child: Text('${bookings.length}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          if (bookings.isNotEmpty) _buildFilterTabs(bookings),
          Expanded(
            child: bookings.isEmpty
              ? _buildEmptyState()
              : filtered.isEmpty
                ? _buildEmptyFilter()
                : _buildList(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(List<Booking> bookings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _Filter.values.map((f) {
            final active = _filter == f;
            final count = _count(bookings, f);
            final label = switch (f) {
              _Filter.all => 'All',
              _Filter.paid => 'Paid',
              _Filter.unpaid => 'Unpaid',
              _Filter.cancelled => 'Cancelled',
            };
            final filterColor = switch (f) {
              _Filter.all => AppColors.primary,
              _Filter.paid => AppColors.primary,
              _Filter.unpaid => AppColors.amber,
              _Filter.cancelled => AppColors.error,
            };
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? filterColor.withOpacity(0.1) : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? filterColor : AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? filterColor : AppColors.textMuted,
                      )),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: active ? filterColor.withOpacity(0.15) : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$count', style: GoogleFonts.poppins(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: active ? filterColor : AppColors.textMuted,
                          )),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(22)),
            child: const Icon(Icons.inbox_rounded, size: 40, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Text('No bookings yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 8),
          Text('Book your first service!', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMuted)),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildEmptyFilter() {
    final label = switch (_filter) {
      _Filter.all => 'all',
      _Filter.paid => 'paid',
      _Filter.unpaid => 'unpaid',
      _Filter.cancelled => 'cancelled',
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off_rounded, size: 40, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text('No $label bookings.', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMuted)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildList(List<Booking> bookings) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final b = bookings[i];
        return BookingCard(
          booking: b,
          onPay: b.isPayable ? () => _openPayment(b) : null,
          onCancel: b.isPayable ? () => ref.read(bookingServiceProvider.notifier).cancelBooking(b.id) : null,
        ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: i * 80)).slideX(begin: 0.08, end: 0);
      },
    );
  }
}
