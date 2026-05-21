import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../models/job.dart';
import '../../providers/providers.dart';
import '../../services/firestore_service.dart';

// ---------------------------------------------------------------------------
// Calendar Screen
// ---------------------------------------------------------------------------

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // First day of the displayed week (Monday)
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekStart =
        DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
  }

  void _goToPrevWeek() =>
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));

  void _goToNextWeek() =>
      setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  @override
  Widget build(BuildContext context) {
    final bookingsAsync =
        ref.watch(weeklyBookingsProvider(_weekStart));
    final profileAsync = ref.watch(workerProfileProvider);

    final weekLabel =
        '${DateFormat('d MMM').format(_weekStart)} – ${DateFormat('d MMM yyyy').format(_weekStart.add(const Duration(days: 6)))}';

    return Scaffold(
      backgroundColor: WorkerColors.background,
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          IconButton(
            tooltip: 'Previous week',
            icon: const Icon(Icons.chevron_left),
            onPressed: _goToPrevWeek,
            iconSize: 28,
          ),
          Center(
            child: Text(weekLabel,
                style: context.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            tooltip: 'Next week',
            icon: const Icon(Icons.chevron_right),
            onPressed: _goToNextWeek,
            iconSize: 28,
          ),
        ],
      ),
      body: Column(
        children: [
          // Smart hints banner
          _SmartHintBanner(),
          // Week header
          _WeekHeaderRow(days: _weekDays),
          // Time grid + available slots
          Expanded(
            child: bookingsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Could not load schedule',
                    style: context.textTheme.bodyMedium
                        ?.copyWith(color: WorkerColors.error)),
              ),
              data: (bookings) {
                final availableSlots =
                    profileAsync.valueOrNull?.availableSlots ?? [];
                return _ScheduleBody(
                  weekDays: _weekDays,
                  bookings: bookings,
                  availableSlots: availableSlots,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Smart hint banner
// ---------------------------------------------------------------------------

class _SmartHintBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: WorkerSizes.pagePadding, vertical: 10),
      color: WorkerColors.accentLight,
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline,
              size: 16, color: WorkerColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'High demand for electricians in DHA between 6–9 PM',
              style: context.textTheme.bodySmall?.copyWith(
                color: WorkerColors.accentDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Week header row
// ---------------------------------------------------------------------------

class _WeekHeaderRow extends StatelessWidget {
  const _WeekHeaderRow({required this.days});

  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();

    return Container(
      color: WorkerColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: List.generate(7, (i) {
          final day = days[i];
          final isToday = day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;
          return Expanded(
            child: Column(
              children: [
                Text(
                  dayNames[i],
                  style: context.textTheme.labelSmall?.copyWith(
                    color:
                        isToday ? WorkerColors.accent : WorkerColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 30,
                  height: 30,
                  decoration: isToday
                      ? const BoxDecoration(
                          color: WorkerColors.accent,
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: isToday
                            ? Colors.white
                            : WorkerColors.text,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Schedule body (time grid + available slots list)
// ---------------------------------------------------------------------------

class _ScheduleBody extends ConsumerWidget {
  const _ScheduleBody({
    required this.weekDays,
    required this.bookings,
    required this.availableSlots,
  });

  final List<DateTime> weekDays;
  final List<Map<String, dynamic>> bookings;
  final List<String> availableSlots;

  static const int _startHour = 7;
  static const int _endHour = 22;

  Color _colorForStatus(String status) {
    switch (status) {
      case 'confirmed':
        return WorkerColors.success;
      case 'en_route':
      case 'in_progress':
      case 'arrived':
        return const Color(0xFF2F80ED);
      case 'completed':
        return WorkerColors.textMuted;
      case 'cancelled':
        return WorkerColors.error;
      default:
        return WorkerColors.textLight;
    }
  }

  /// Returns bookings that fall within the given [day] + [hour].
  List<Map<String, dynamic>> _bookingsForSlot(
      DateTime day, int hour) {
    return bookings.where((b) {
      final slot = (b['slot'] as Timestamp?)?.toDate();
      if (slot == null) return false;
      return slot.year == day.year &&
          slot.month == day.month &&
          slot.day == day.day &&
          slot.hour == hour;
    }).toList();
  }

  bool _isSlotBlocked(DateTime day, int hour) {
    final slotKey =
        '${DateFormat('yyyy-MM-dd').format(day)}_${hour.toString().padLeft(2, '0')}:00';
    return availableSlots.contains(slotKey);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _TimeGrid(
            weekDays: weekDays,
            bookingsForSlot: _bookingsForSlot,
            isSlotBlocked: _isSlotBlocked,
            colorForStatus: _colorForStatus,
            availableSlots: availableSlots,
          ),
        ),
        SliverToBoxAdapter(
          child: _AvailableSlotsSection(availableSlots: availableSlots),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Time grid
// ---------------------------------------------------------------------------

class _TimeGrid extends ConsumerWidget {
  const _TimeGrid({
    required this.weekDays,
    required this.bookingsForSlot,
    required this.isSlotBlocked,
    required this.colorForStatus,
    required this.availableSlots,
  });

  final List<DateTime> weekDays;
  final List<Map<String, dynamic>> Function(DateTime, int) bookingsForSlot;
  final bool Function(DateTime, int) isSlotBlocked;
  final Color Function(String) colorForStatus;
  final List<String> availableSlots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const startHour = 7;
    const endHour = 22;

    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
      },
      border: TableBorder.all(color: WorkerColors.divider, width: 0.5),
      children: List.generate(endHour - startHour, (rowIndex) {
        final hour = startHour + rowIndex;
        return TableRow(
          children: [
            // Time label
            Container(
              color: WorkerColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: context.textTheme.labelSmall
                    ?.copyWith(color: WorkerColors.textMuted),
              ),
            ),
            // 7 day columns
            ...List.generate(7, (dayIndex) {
              final day = weekDays[dayIndex];
              final slotBookings = bookingsForSlot(day, hour);
              final blocked = isSlotBlocked(day, hour);

              if (slotBookings.isNotEmpty) {
                final booking = slotBookings.first;
                final status = booking['status'] as String? ?? '';
                final color = colorForStatus(status);
                final jobRef = booking['id'] as String? ?? '';
                final serviceType =
                    booking['service_type'] as String? ?? '';

                return GestureDetector(
                  onTap: () => context.push('/jobs/$jobRef'),
                  child: Container(
                    height: 52,
                    margin: const EdgeInsets.all(1),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          serviceType.snakeToTitle(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          jobRef.length > 8
                              ? '#${jobRef.substring(0, 8)}'
                              : '#$jobRef',
                          style: TextStyle(
                            fontSize: 8,
                            color: color.withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Empty slot — tap to block/unblock
              return GestureDetector(
                onTap: () => _toggleSlot(context, ref, day, hour),
                child: Container(
                  height: 52,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: blocked
                        ? const Color(0xFFF0F0F5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: blocked
                      ? const Center(
                          child: Icon(Icons.block,
                              size: 14, color: WorkerColors.textLight),
                        )
                      : null,
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  Future<void> _toggleSlot(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
    int hour,
  ) async {
    final profile = ref.read(workerProfileProvider).valueOrNull;
    if (profile == null) return;

    final slotKey =
        '${DateFormat('yyyy-MM-dd').format(day)}_${hour.toString().padLeft(2, '0')}:00';

    final currentSlots = List<String>.from(profile.availableSlots);
    if (currentSlots.contains(slotKey)) {
      currentSlots.remove(slotKey);
    } else {
      currentSlots.add(slotKey);
    }

    try {
      await ref
          .read(firestoreServiceProvider)
          .updateWorkerProfile(profile.id, {'available_slots': currentSlots});
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar('Failed to update slot', isError: true);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Available slots section
// ---------------------------------------------------------------------------

class _AvailableSlotsSection extends ConsumerWidget {
  const _AvailableSlotsSection({required this.availableSlots});

  final List<String> availableSlots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(WorkerSizes.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Blocked Slots', style: context.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (availableSlots.isEmpty)
            Text(
              'No slots blocked. Tap an empty cell to block it.',
              style: context.textTheme.bodyMedium
                  ?.copyWith(color: WorkerColors.textMuted),
            )
          else
            ...availableSlots.map((slot) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: WorkerColors.surface,
                  borderRadius:
                      BorderRadius.circular(WorkerSizes.buttonRadius),
                  boxShadow: WorkerColors.cardShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_busy_outlined,
                        size: WorkerSizes.iconSm,
                        color: WorkerColors.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatSlotKey(slot),
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove block',
                      icon: const Icon(Icons.delete_outline,
                          color: WorkerColors.error,
                          size: WorkerSizes.iconSm),
                      onPressed: () => _removeSlot(context, ref, slot),
                      constraints: const BoxConstraints(
                        minWidth: WorkerSizes.minTouchTarget,
                        minHeight: WorkerSizes.minTouchTarget,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatSlotKey(String key) {
    // Format: "2026-05-21_09:00" → "Thu, 21 May  09:00"
    final parts = key.split('_');
    if (parts.length < 2) return key;
    try {
      final date = DateTime.parse(parts[0]);
      return '${DateFormat('EEE, d MMM').format(date)}  ${parts[1]}';
    } catch (_) {
      return key;
    }
  }

  Future<void> _removeSlot(
      BuildContext context, WidgetRef ref, String slotKey) async {
    final profile = ref.read(workerProfileProvider).valueOrNull;
    if (profile == null) return;

    final updated = List<String>.from(profile.availableSlots)
      ..remove(slotKey);

    try {
      await ref
          .read(firestoreServiceProvider)
          .updateWorkerProfile(profile.id, {'available_slots': updated});
    } catch (_) {
      if (context.mounted) {
        context.showSnackBar('Failed to update', isError: true);
      }
    }
  }
}
