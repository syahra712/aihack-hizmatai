import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Color palette
// ---------------------------------------------------------------------------

class WorkerColors {
  WorkerColors._();

  static const Color accent = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFFF0EB);
  static const Color accentDark = Color(0xFFE05520);

  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;

  static const Color text = Color(0xFF1A1D26);
  static const Color textMuted = Color(0xFF7C8DB0);
  static const Color textLight = Color(0xFFB0BAD3);

  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFFEAF7EF);

  static const Color warning = Color(0xFFF2994A);
  static const Color warningLight = Color(0xFFFFF5EB);

  static const Color error = Color(0xFFEB5757);
  static const Color errorLight = Color(0xFFFEEEEE);

  static const Color divider = Color(0xFFECEFF6);

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 30,
      offset: Offset(0, 8),
    ),
  ];
}

// ---------------------------------------------------------------------------
// Size tokens
// ---------------------------------------------------------------------------

class WorkerSizes {
  WorkerSizes._();

  static const double minTouchTarget = 52.0;
  static const double bodyFont = 16.0;
  static const double headingFont = 22.0;
  static const double smallFont = 13.0;
  static const double captionFont = 11.0;

  static const double cardRadius = 20.0;
  static const double buttonRadius = 14.0;
  static const double chipRadius = 30.0;
  static const double inputRadius = 14.0;

  static const double pagePadding = 20.0;
  static const double cardPadding = 16.0;
  static const double sectionSpacing = 24.0;

  static const double iconSm = 18.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;

  static const double avatarSm = 36.0;
  static const double avatarMd = 52.0;
  static const double avatarLg = 80.0;
}

// ---------------------------------------------------------------------------
// Theme
// ---------------------------------------------------------------------------

class WorkerTheme {
  WorkerTheme._();

  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: WorkerColors.accent,
      brightness: Brightness.light,
      primary: WorkerColors.accent,
      onPrimary: Colors.white,
      secondary: WorkerColors.accentDark,
      onSecondary: Colors.white,
      surface: WorkerColors.surface,
      onSurface: WorkerColors.text,
      error: WorkerColors.error,
      onError: Colors.white,
    );

    final textTheme = GoogleFonts.poppinsTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: WorkerColors.text,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: WorkerColors.text,
          letterSpacing: -0.3,
        ),
        headlineLarge: TextStyle(
          fontSize: WorkerSizes.headingFont,
          fontWeight: FontWeight.w700,
          color: WorkerColors.text,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: WorkerColors.text,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: WorkerColors.text,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: WorkerColors.text,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: WorkerColors.text,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: WorkerColors.text,
        ),
        bodyLarge: TextStyle(
          fontSize: WorkerSizes.bodyFont,
          fontWeight: FontWeight.w400,
          color: WorkerColors.text,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: WorkerColors.text,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: WorkerSizes.smallFont,
          fontWeight: FontWeight.w400,
          color: WorkerColors.textMuted,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: WorkerColors.text,
        ),
        labelSmall: TextStyle(
          fontSize: WorkerSizes.captionFont,
          fontWeight: FontWeight.w500,
          color: WorkerColors.textMuted,
          letterSpacing: 0.3,
        ),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: WorkerColors.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: WorkerColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: WorkerColors.text),
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
      ),

      // Card
      cardTheme: CardTheme(
        color: WorkerColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WorkerSizes.cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WorkerColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, WorkerSizes.minTouchTarget),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WorkerSizes.buttonRadius),
          ),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WorkerColors.accent,
          minimumSize: const Size(double.infinity, WorkerSizes.minTouchTarget),
          side: const BorderSide(color: WorkerColors.accent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WorkerSizes.buttonRadius),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: WorkerColors.accent,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(0, WorkerSizes.minTouchTarget),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WorkerColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WorkerSizes.inputRadius),
          borderSide: const BorderSide(color: WorkerColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WorkerSizes.inputRadius),
          borderSide: const BorderSide(color: WorkerColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WorkerSizes.inputRadius),
          borderSide:
              const BorderSide(color: WorkerColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WorkerSizes.inputRadius),
          borderSide: const BorderSide(color: WorkerColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WorkerSizes.inputRadius),
          borderSide:
              const BorderSide(color: WorkerColors.error, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: WorkerColors.textLight,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: WorkerColors.textMuted,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: WorkerColors.accent,
          fontWeight: FontWeight.w500,
        ),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: WorkerColors.accent,
        unselectedItemColor: WorkerColors.textMuted,
        elevation: 12,
        type: BottomNavigationBarType.fixed,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: WorkerColors.accentLight,
        labelStyle: textTheme.labelSmall?.copyWith(
          color: WorkerColors.accent,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WorkerSizes.chipRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: WorkerColors.divider,
        thickness: 1,
        space: 1,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: WorkerColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return WorkerColors.textLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return WorkerColors.accent;
          }
          return WorkerColors.divider;
        }),
      ),

      // ProgressIndicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: WorkerColors.accent,
        linearTrackColor: WorkerColors.accentLight,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        iconColor: WorkerColors.textMuted,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        minLeadingWidth: 24,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: WorkerColors.text,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
