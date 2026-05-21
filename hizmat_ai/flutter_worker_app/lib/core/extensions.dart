import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// BuildContext helpers
// ---------------------------------------------------------------------------

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEB5757) : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DateTime extensions
// ---------------------------------------------------------------------------

extension DateTimeExtensions on DateTime {
  /// Returns a human-readable relative time string, e.g. "2 hours ago".
  String timeAgo() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    }
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return '$w ${w == 1 ? 'week' : 'weeks'} ago';
    }
    if (diff.inDays < 365) {
      final mo = (diff.inDays / 30).floor();
      return '$mo ${mo == 1 ? 'month' : 'months'} ago';
    }
    final y = (diff.inDays / 365).floor();
    return '$y ${y == 1 ? 'year' : 'years'} ago';
  }

  /// Formats as "Mon, 21 May 2026"
  String toDisplayDate() => DateFormat('EEE, d MMM yyyy').format(this);

  /// Formats as "09:30 AM"
  String toDisplayTime() => DateFormat('hh:mm a').format(this);

  /// Formats as "21 May 2026, 09:30 AM"
  String toDisplayDateTime() =>
      DateFormat('d MMM yyyy, hh:mm a').format(this);

  /// Returns true if the date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if the date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }
}

// ---------------------------------------------------------------------------
// int / double extensions — currency formatting
// ---------------------------------------------------------------------------

extension IntExtensions on int {
  /// Returns a formatted PKR string, e.g. "PKR 1,200"
  String formatPKR() {
    final formatter = NumberFormat('#,##0', 'en_US');
    return 'PKR ${formatter.format(this)}';
  }
}

extension DoubleExtensions on double {
  /// Returns a formatted PKR string, e.g. "PKR 1,200.50"
  String formatPKR({bool showDecimals = false}) {
    final pattern = showDecimals ? '#,##0.00' : '#,##0';
    final formatter = NumberFormat(pattern, 'en_US');
    return 'PKR ${formatter.format(this)}';
  }
}

// ---------------------------------------------------------------------------
// String extensions
// ---------------------------------------------------------------------------

extension StringExtensions on String {
  /// Capitalises the first letter of the string.
  String capitalised() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Converts snake_case to Title Case.
  String snakeToTitle() {
    return split('_').map((w) => w.capitalised()).join(' ');
  }
}
