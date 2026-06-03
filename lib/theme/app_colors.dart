import 'package:flutter/material.dart';
import '../models/gender.dart';

/// โทนสี Soulive — ท้องฟ้าออโรร่าพาสเทล fluid
class AppColors {
  AppColors._();

  // ปรับเป็นโปร่งใสเพื่อให้เลเยอร์ออโรร่าด้านหลังแสดงผลได้สมบูรณ์
  static const background = Colors.transparent; 
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1E1E2C);
  static const textSecondary = Color(0xFF5C6BC0); 
  static const textMuted = Color(0xFF9FA8DA);

  // ชุดสีสำหรับ "พื้นหลังโทนท้องฟ้าออโรร่าพาสเทล fluid"
  static const auroraStart = Color(0xFFA5B4FC); // สีฟ้าอมม่วงออโรร่าช่วงบนสุด (Soft Indigo)
  static const auroraMid = Color(0xFFE9D5FF);   // สีม่วงลาเวนเดอร์พาสเทลนุ่มๆ ช่วงกลาง (Soft Lavender)
  static const auroraEnd = Color(0xFFE8F1FF);   // สีขาวไอซ์บลูสว่างใสช่วงล่าง (Ice Blue)
  static const auroraGlow = Color(0xFFFBCFE8);  // แสงออโรร่าชมพูฟุ้งสะท้อนมุมจอ (Pastel Pink Glow)
  static const fluidShape = Color(0xFFC7D2FE);  // สีฟ้าพาสเทลสำหรับวาดส่วนโค้งมน Fluid

  static const brandPink = Color(0xFFEC407A); 
  static const brandPinkDark = Color(0xFFD81B60);
  static const accent = Color(0xFF5C6BC0); 
  static const accentSoft = Color(0xFFE8EAF6);
  static const heartRed = Color(0xFFE85D75);
  static const navy = Color(0xFF2D2E4F);
  static const border = Color(0xFFE8E4E0);
  static const chipBg = Color(0xFFF3F0EE);

  static const navActive = Color(0xFFD67B88);
  static const navInactive = Color(0xFF9E9EAA);

  static const femaleBg = Color(0xFFFFF0F5);
  static const femaleBorder = Color(0xFFF5D0DC);
  static const maleBg = Color(0xFFEEF6FF);
  static const maleBorder = Color(0xFFC8DDF5);
  static const otherBg = Color(0xFFF3EEFF);
  static const otherBorder = Color(0xFFD8CCF5);

  static const verified = Color(0xFFD67B88);

  static Color cardBackground(Gender gender) {
    switch (gender) {
      case Gender.female:
        return femaleBg;
      case Gender.male:
        return maleBg;
      case Gender.other:
        return otherBg;
    }
  }

  static Color cardBorder(Gender gender) {
    switch (gender) {
      case Gender.female:
        return femaleBorder;
      case Gender.male:
        return maleBorder;
      case Gender.other:
        return otherBorder;
    }
  }

  @Deprecated('Use cardBorder')
  static Color cardAccent(Gender gender) => cardBorder(gender);
}