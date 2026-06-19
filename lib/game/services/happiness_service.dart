import '../models/settlement.dart';
import '../models/building.dart';

class HappinessService {
  // คำนวณ happiness ใหม่จาก state ปัจจุบัน
  static int calculateHappiness({
    required Settlement settlement,
    required List<Building> buildings,
    required bool wasAttackedRecently, // โดนบุกใน 1 ชั่วโมงที่ผ่านมา
  }) {
    int happiness = settlement.happiness;
    final now = DateTime.now();
    final hoursSinceUpdate =
        now.difference(settlement.happinessUpdatedAt).inHours;

    if (hoursSinceUpdate == 0) return happiness;

    // ตรวจสอบเงื่อนไข happiness
    final hasTavern = buildings.any(
      (b) => b.buildingType == 'tavern'
    );
    final hasShrine = buildings.any(
      (b) => b.buildingType == 'shrine'
    );
    final hasLiquor = settlement.liquor > 0;
    final hasRice   = settlement.rice > 0;

    // คำนวณ delta ต่อชั่วโมง
    int deltaPerHour = 0;

    if (hasRice)   deltaPerHour += 2;
    else           deltaPerHour -= 3;

    if (hasTavern && hasLiquor) deltaPerHour += 3;
    else if (hasTavern)         deltaPerHour -= 1;

    if (hasShrine) deltaPerHour += 2;

    if (wasAttackedRecently) deltaPerHour -= 5;

    happiness += deltaPerHour * hoursSinceUpdate;
    return happiness.clamp(0, 100);
  }

  // สถานะประชาชนจาก happiness
  static String getStatus(int happiness) {
    if (happiness >= 70) return 'พอใจ';
    if (happiness >= 40) return 'เฉยๆ';
    if (happiness >= 20) return 'ไม่พอใจ';
    return 'วิกฤต';
  }

  // ถึงเวลาลดประชากรไหม
  static bool shouldDecreasePopulation(Settlement settlement) {
    if (settlement.happiness >= 20) return false;

    // ต้องไม่พอใจนาน 24 ชั่วโมงก่อนถึงจะลด
    final hoursSinceUpdate =
        DateTime.now().difference(settlement.happinessUpdatedAt).inHours;
    return hoursSinceUpdate >= 24;
  }
}