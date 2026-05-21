import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFFF6F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF0F2F8);
  static const primary = Color(0xFF00B894);
  static const primaryDim = Color(0xFF009B7D);
  static const primaryLight = Color(0xFFE8FBF5);
  static const accent = Color(0xFF6C5CE7);
  static const text = Color(0xFF1A1D26);
  static const textMuted = Color(0xFF7C8DB0);
  static const amber = Color(0xFFFFAA33);
  static const error = Color(0xFFFF5252);
  static const cardBg = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE8ECF4);
  static const glass = Color(0xCCFFFFFF);

  static const shadowLight = Color(0x14000000);
  static const shadowMedium = Color(0x1F000000);

  static const intentAgent = Color(0xFF7C3AED);
  static const rankAgent = Color(0xFF0284C7);
  static const priceAgent = Color(0xFF059669);
  static const bookingAgent = Color(0xFFF59E0B);
  static const followupAgent = Color(0xFFEF4444);
  static const discoveryAgent = Color(0xFF0891B2);
  static const adkOrchestrator = Color(0xFF6C5CE7);
}

class AppShadows {
  static List<BoxShadow> get soft => [
    const BoxShadow(color: Color(0x0A000000), offset: Offset(0, 2), blurRadius: 8),
    const BoxShadow(color: Color(0x05000000), offset: Offset(0, 8), blurRadius: 24),
  ];

  static List<BoxShadow> get card => [
    const BoxShadow(color: Color(0x0D000000), offset: Offset(0, 4), blurRadius: 16),
    const BoxShadow(color: Color(0x08000000), offset: Offset(0, 12), blurRadius: 40),
  ];

  static List<BoxShadow> get elevated => [
    const BoxShadow(color: Color(0x14000000), offset: Offset(0, 8), blurRadius: 24),
    const BoxShadow(color: Color(0x0A000000), offset: Offset(0, 20), blurRadius: 60),
  ];

  static List<BoxShadow> get primaryGlow => [
    BoxShadow(color: AppColors.primary.withOpacity(0.25), offset: const Offset(0, 6), blurRadius: 20),
  ];
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.text,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 14),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
