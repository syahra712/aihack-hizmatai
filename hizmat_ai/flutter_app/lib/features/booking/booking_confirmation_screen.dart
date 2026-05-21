import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import 'live_tracker.dart';
import 'payment_sheet.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingConfirmationScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends ConsumerState<BookingConfirmationScreen> {
  bool _copied = false;
  bool _showCancelConfirm = false;

  void _copyId(String id) {
    Clipboard.setData(ClipboardData(text: id));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking ID copied!', style: GoogleFonts.poppins(fontSize: 12)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, ) {
    final bookings = ref.watch(bookingServiceProvider);
    final booking = bookings.where((b) => b.id == widget.bookingId).firstOrNull;

    if (booking == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Booking not found', style: GoogleFonts.poppins(color: AppColors.textMuted))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildHeader(booking),
              const SizedBox(height: 20),
              _buildProviderCard(booking),
              const SizedBox(height: 16),
              _buildDetailsGrid(booking),
              const SizedBox(height: 16),
              _buildPriceBreakdown(booking),
              if (booking.isPaid)
                LiveTracker(active: true, providerName: booking.providerName),
              const SizedBox(height: 16),
              if (_showCancelConfirm && booking.isPayable)
                _buildCancelConfirm(booking),
              _buildActions(booking),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Booking booking) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00B894)]),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 24, spreadRadius: 4)],
          ),
          child: Icon(
            booking.isPaid ? Icons.check_rounded : Icons.event_available_rounded,
            size: 36,
            color: Colors.white,
          ),
        )
            .animate()
            .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut)
            .then()
            .shimmer(duration: 600.ms, color: Colors.white.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(
          booking.isPaid ? 'Paid & Confirmed!' : 'Booking Confirmed!',
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _copyId(booking.id),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                booking.id,
                style: GoogleFonts.sourceCodePro(fontSize: 13, color: AppColors.textMuted, letterSpacing: 0.5),
              ),
              const SizedBox(width: 6),
              Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 14,
                color: _copied ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
        const SizedBox(height: 8),
        Text(
          'PKR ${_fmt(booking.estimatedCost)}',
          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary),
        ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
      ],
    );
  }

  Widget _buildProviderCard(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                booking.providerName.split(' ').take(2).map((w) => w[0]).join(),
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.providerName, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 13, color: AppColors.amber),
                    const SizedBox(width: 3),
                    Text('4.8', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.amber)),
                    const SizedBox(width: 8),
                    Icon(Icons.verified_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text('Certified', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDetailsGrid(Booking booking) {
    final items = [
      (Icons.location_on_rounded, 'Area', booking.city),
      (Icons.calendar_today_rounded, 'Date', DateFormat('dd MMM yyyy').format(booking.dateTime)),
      (Icons.access_time_rounded, 'Time', DateFormat('hh:mm a').format(booking.dateTime)),
      (Icons.phone_rounded, 'Contact', booking.providerPhone ?? '+92 300 1234567'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: items.asMap().entries.map((e) {
        final (icon, label, value) = e.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textMuted)),
                    Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: 450 + e.key * 80));
      }).toList(),
    );
  }

  Widget _buildPriceBreakdown(Booking booking) {
    final base = booking.estimatedCost;
    final laborRate = (base * 0.55).round();
    final visitFee = 250;
    final materials = (base * 0.15).round();
    final urgency = (base * 0.05).round();
    final gst = (base * 0.05).round();
    final platformFee = (base * 0.03).round();
    final total = laborRate + visitFee + materials + urgency + gst + platformFee;

    final rows = [
      ('Labor (2 hrs × ${_fmt(laborRate ~/ 2)}/hr)', _fmt(laborRate), false, false),
      ('Visit fee', _fmt(visitFee), false, false),
      ('Materials (est.)', _fmt(materials), false, false),
      ('Urgency surcharge', _fmt(urgency), false, true),
      ('GST (5%)', _fmt(gst), false, false),
      ('Platform fee', _fmt(platformFee), false, false),
      ('Total Estimate', 'PKR ${_fmt(total)}', true, false),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D26).withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Breakdown', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 10),
          ...rows.map((r) {
            final (label, value, isTotal, isSaffron) = r;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: isTotal
                  ? BoxDecoration(border: Border(top: BorderSide(color: AppColors.cardBorder)))
                  : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: isTotal ? 14 : 12,
                        fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
                        color: isSaffron ? AppColors.amber : isTotal ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: isTotal ? 16 : 12,
                      fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                      color: isSaffron ? AppColors.amber : isTotal ? AppColors.primary : AppColors.text,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 550.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCancelConfirm(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
              const SizedBox(width: 8),
              Text('Are you sure?', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'This cannot be undone. You will need to book again.',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(bookingServiceProvider.notifier).cancelBooking(booking.id);
                    context.go('/bookings');
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('Yes, cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showCancelConfirm = false),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('Keep it', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).shake(hz: 2, offset: const Offset(2, 0), duration: 300.ms);
  }

  Widget _buildActions(Booking booking) {
    return Column(
      children: [
        if (booking.isPayable)
          GestureDetector(
            onTap: () => PaymentSheet.show(
              context,
              amount: booking.estimatedCost,
              providerName: booking.providerName,
              bookingId: booking.id,
              onSuccess: (result) {
                ref.read(bookingServiceProvider.notifier).markAsPaid(booking.id, last4: result.last4);
              },
            ),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00B894)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppShadows.primaryGlow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Pay PKR ${_fmt(booking.estimatedCost)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 650.ms),
        if (booking.isPaid)
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Paid · PKR ${_fmt(booking.estimatedCost)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15)),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 650.ms),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => context.go('/home'),
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: booking.isPaid ? const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00B894)]) : null,
              color: booking.isPaid ? null : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              boxShadow: booking.isPaid ? AppShadows.primaryGlow : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_rounded, color: booking.isPaid ? Colors.white : AppColors.textMuted, size: 20),
                const SizedBox(width: 8),
                Text('Back to Home', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: booking.isPaid ? Colors.white : AppColors.textMuted, fontSize: 15)),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/bookings'),
                icon: const Icon(Icons.list_alt_rounded, color: AppColors.primary, size: 16),
                label: Text('Bookings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                ),
              ),
            ),
            if (booking.isPayable) ...[
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showCancelConfirm = !_showCancelConfirm),
                  icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 16),
                  label: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.error, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                  ),
                ),
              ),
            ],
          ],
        ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
      ],
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
