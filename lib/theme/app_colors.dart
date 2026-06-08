import 'package:flutter/material.dart';
import '../models/gender.dart';

/// โทนสีหลักของแอป พร้อมสีไอคอนแยกประเภท
class AppColors {
  AppColors._();

  // Core Colors
  static const primary = Color(0xFF5B5FEF);
  static const onPrimary = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF20212B);
  static const background = Color(0xFFF7F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF667085);
  static const destructive = Color(
    0xFFFF6B6B,
  ); // Soft red for notifications/errors
  static const destructiveAccent = destructive;
  static const border = Color(0xFFE4E7EC);
  static const background24 = Color(
    0x3DFFFFFF,
  ); // White with 24% opacity (0x3D is ~24%)

  static const iconBlue = Color(0xFF2563EB);
  static const iconPurple = Color(0xFF7C3AED);
  static const iconPink = Color(0xFFEC4899);
  static const iconOrange = Color(0xFFF97316);
  static const iconGreen = Color(0xFF16A34A);
  static const iconTeal = Color(0xFF0891B2);

  // Legacy mappings for compatibility
  static const accent = iconTeal;
  static const accentSoft = Color(0xFFEFF6FF);
  static const textMuted = textSecondary;
  static const brandPink = iconPink;
  static const brandPinkDark = Color(0xFFBE185D);
  static const heartRed = destructive;
  static const navy = Color(0xFF111827);
  static const chipBg = surface;
  static const navActive = primary;
  static const navInactive = textSecondary;
  static const verified = iconBlue;

  // Gender colors
  static const femaleBg = surface;
  static const femaleBorder = border;
  static const maleBg = surface;
  static const maleBorder = border;
  static const otherBg = surface;
  static const otherBorder = border;

  static Color cardBackground(Gender gender) => surface;
  static Color cardBorder(Gender gender) => border;

  @Deprecated('Use cardBorder')
  static Color cardAccent(Gender gender) => border;

  // Aurora colors - deprecated but mapped
  static const auroraStart = background;
  static const auroraMid = background;
  static const auroraEnd = background;
  static const auroraGlow = surface;
  static const fluidShape = border;
}
