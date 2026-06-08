import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.destructive,
        brightness: Brightness.light,
      ),
    );

    // Using Noto Sans Thai as primary font
    final textTheme = GoogleFonts.notoSansThaiTextTheme(base.textTheme).copyWith(
      // App name / heading: 22px, weight 500
      headlineMedium: GoogleFonts.notoSansThai(
        fontSize: 22, 
        fontWeight: FontWeight.w500, 
        color: AppColors.textPrimary,
      ),
      // Screen title: 16px, weight 500
      titleLarge: GoogleFonts.notoSansThai(
        fontSize: 16, 
        fontWeight: FontWeight.w500, 
        color: AppColors.textPrimary,
      ),
      // Body / chat text: 13px, weight 400
      bodyLarge: GoogleFonts.notoSansThai(
        fontSize: 13, 
        fontWeight: FontWeight.w400, 
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.notoSansThai(
        fontSize: 13, 
        fontWeight: FontWeight.w400, 
        color: AppColors.textPrimary,
      ),
      // Meta info (distance, job): 12px, weight 400, opacity 75%
      bodySmall: GoogleFonts.notoSansThai(
        fontSize: 12, 
        fontWeight: FontWeight.w400, 
        color: AppColors.textPrimary.withOpacity(0.75),
      ),
      // Question box text: 12px, weight 400
      labelLarge: GoogleFonts.notoSansThai(
        fontSize: 12, 
        fontWeight: FontWeight.w400, 
        color: AppColors.textPrimary,
      ),
      // Tags and chips: 10px, weight 400
      labelMedium: GoogleFonts.notoSansThai(
        fontSize: 10, 
        fontWeight: FontWeight.w400, 
        color: AppColors.textSecondary,
      ),
      // Timestamps / captions: 10px, weight 400
      labelSmall: GoogleFonts.notoSansThai(
        fontSize: 10, 
        fontWeight: FontWeight.w400, 
        color: AppColors.textSecondary,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary.withOpacity(0.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
      ),
    );
  }
}
