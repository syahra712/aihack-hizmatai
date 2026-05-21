import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/provider.dart';
import '../../services/booking_service.dart';
import 'provider_card.dart';

class ProviderPickerSheet {
  static void show(
    BuildContext context, {
    required List<ServiceProvider> providers,
    required String detectedCity,
    required WidgetRef ref,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _Sheet(providers: providers, detectedCity: detectedCity, ref: ref),
    );
  }
}

class _Sheet extends StatelessWidget {
  final List<ServiceProvider> providers;
  final String detectedCity;
  final WidgetRef ref;
  const _Sheet({required this.providers, required this.detectedCity, required this.ref});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), offset: const Offset(0, -8), blurRadius: 30),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 14),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Providers',
                            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
                          ),
                          Text(
                            'Ranked by AI for quality & availability',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: providers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) {
                    final p = providers[i];
                    return ProviderCard(
                      provider: p,
                      rank: i + 1,
                      onBook: () async {
                        final booking = await ref.read(bookingServiceProvider.notifier).createBooking(p, detectedCity);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        context.push('/booking-confirmation/${booking.id}');
                      },
                    ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: i * 150)).slideY(begin: 0.12, end: 0);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
