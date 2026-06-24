import '../models/settlement.dart';
import '../models/building.dart';

class ProductionService {
  static int tickDurationMinutes = 5;
  static int offlineCapMinutes = 480;

  // คำนวณ resource ที่ได้รับตั้งแต่ครั้งล่าสุดที่เปิดแอป
  static Map<String, int> calculateOfflineProduction({
    required Settlement settlement,
    required List<Building> buildings,
    required DateTime lastOnlineAt,
  }) {
    final now = DateTime.now();
    final minutesOffline = now.difference(lastOnlineAt).inMinutes;

    // จำกัดสูงสุด (offline cap)
    final cappedMinutes = minutesOffline.clamp(0, offlineCapMinutes);
    final ticks = (cappedMinutes / tickDurationMinutes).floor();

    if (ticks == 0) return {};

    final production = <String, int>{
      'wood': 0, 'iron': 0, 'rice': 0, 'liquor': 0,
    };

    for (final building in buildings) {
      // โรงกลั่นต้องมีข้าวก่อนถึงผลิตสุราได้
      if (building.buildingType == 'distillery') {
        if (settlement.rice <= 0) continue;
      }

      final prod = building.productionPerTick;
      prod.forEach((resource, amount) {
        production[resource] = (production[resource] ?? 0) + (amount * ticks);
      });
    }

    return production;
  }

  // คำนวณ production rate ต่อชั่วโมง (แสดงใน UI)
  static Map<String, int> calculateHourlyRate(List<Building> buildings) {
    final ticksPerHour = 60 ~/ tickDurationMinutes; // = 12
    final rate = <String, int>{
      'wood': 0, 'iron': 0, 'rice': 0, 'liquor': 0,
    };

    for (final building in buildings) {
      final prod = building.productionPerTick;
      prod.forEach((resource, amount) {
        rate[resource] = (rate[resource] ?? 0) + (amount * ticksPerHour);
      });
    }

    return rate;
  }
}