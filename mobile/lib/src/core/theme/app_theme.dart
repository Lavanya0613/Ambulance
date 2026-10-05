import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Chekup Green Palette (Reference 3 - Source of Truth)
  static const Color chekupGreen = Color(0xFF5BA438);       // Primary Leaf Green
  static const Color chekupGreenDark = Color(0xFF47842B);   // Darker shade for depth
  static const Color chekupGreenLight = Color(0xFFF0FDF4);  // Light green background tint
  static const Color chekupGreenBorder = Color(0xFFDCFCE7); // Soft green border
  
  static const Color primary = chekupGreen;
  static const Color primaryDark = chekupGreenDark;
  static const Color primaryLight = chekupGreenLight;
  
  static const Color secondary = Color(0xFF0F2851); // Chekup Navy / Dark Slate
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  
  static const Color red = Color(0xFFEF4444);
  static const Color amber = Color(0xFFF59E0B);
  static const Color green = Color(0xFF5BA438);
  static const Color blue = Color(0xFF1565C0);
  
  static const Color textPrimary = Color(0xFF0F2851);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);

  // Legacy colors for Vendor App
  static const Color darkBlue = Color(0xFF1E3A5F);
  static const Color darkBlueLight = Color(0xFFE8ECF1);
  static const Color greenLight = Color(0xFFF1F8EB);
  static const Color amberLight = Color(0xFFFEF7E6);
  static const Color redLight = Color(0xFFFCEBEA);
  static const Color cardBorder = Color(0xFFE5E7EB);
}

class AppTheme {
  static ThemeData get light {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.red,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        displayMedium: baseTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        margin: const EdgeInsets.only(bottom: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
        hintStyle: GoogleFonts.poppins(color: AppColors.textMuted, fontWeight: FontWeight.w400, fontSize: 13),
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 13),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: const BorderSide(color: AppColors.border),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 11),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.secondary,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
    );
  }
}
