class Building {
  final String id;
  final String settlementId;
  final String buildingType;
  final int level;
  final int? houseVariant;
  final bool isUpgrading;
  final DateTime? upgradeFinishAt;
  final DateTime createdAt;

  const Building({
    required this.id,
    required this.settlementId,
    required this.buildingType,
    required this.level,
    this.houseVariant,
    required this.isUpgrading,
    this.upgradeFinishAt,
    required this.createdAt,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'],
      settlementId: json['settlement_id'],
      buildingType: json['building_type'],
      level: json['level'],
      houseVariant: json['house_variant'],
      isUpgrading: json['is_upgrading'] ?? false,
      upgradeFinishAt: json['upgrade_finish_at'] != null
          ? DateTime.parse(json['upgrade_finish_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // เวลาที่เหลือในการอัปเกรด
  Duration? get upgradeTimeRemaining {
    if (!isUpgrading || upgradeFinishAt == null) return null;
    final remaining = upgradeFinishAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get upgradeComplete {
    if (!isUpgrading || upgradeFinishAt == null) return false;
    return DateTime.now().isAfter(upgradeFinishAt!);
  }

  // ชื่อแสดงผล
  String get displayName {
    const names = {
      'sawmill': 'โรงไม้',
      'smelter': 'โรงหลอม',
      'rice_farm': 'นาข้าว',
      'distillery': 'โรงกลั่น',
      'house': 'บ้านเรือน',
      'tavern': 'ร้านเหล้าตอง',
      'shrine': 'ศาลเจ้า',
      'barracks': 'ค่ายทหาร',
      'elephant_camp': 'โรงช้าง',
      'smithy': 'โรงตีเหล็ก',
      'wall': 'กำแพงเมือง',
      'cannon': 'ปืนใหญ่',
      'watchtower': 'หอสังเกตการณ์',
      'town_hall': 'ศาลากลาง',
    };
    return names[buildingType] ?? buildingType;
  }

  static Map<String, dynamic>? remoteConfig;

  // ต้นทุนอัปเกรด level ถัดไป
  Map<String, int> get upgradeCost {
    final multiplier = level; // level 1→2 = x1, 2→3 = x2 ...
    if (remoteConfig != null && remoteConfig![buildingType] != null) {
      final config = remoteConfig![buildingType];
      final baseCost = config['base_cost'] as Map<String, dynamic>?;
      if (baseCost != null) {
        return baseCost.map(
          (k, v) => MapEntry(k, (v as num).toInt() * multiplier),
        );
      }
    }
    const baseCosts = {
      'sawmill': {'wood': 30, 'iron': 10},
      'smelter': {'wood': 20, 'iron': 30},
      'rice_farm': {'wood': 40, 'iron': 10},
      'distillery': {'wood': 30, 'iron': 20},
      'house': {'wood': 50, 'iron': 10},
      'tavern': {'wood': 40, 'iron': 20},
      'shrine': {'wood': 60, 'iron': 30},
      'barracks': {'wood': 50, 'iron': 40},
      'elephant_camp': {'wood': 80, 'iron': 60},
      'smithy': {'wood': 40, 'iron': 50},
      'wall':          {'wood': 30, 'iron': 60},
'cannon':        {'wood': 40, 'iron': 80},
'watchtower':    {'wood': 50, 'iron': 30},
      'town_hall': {'wood': 80, 'iron': 80},
    };
    final base = baseCosts[buildingType] ?? {'wood': 50, 'iron': 50};
    return base.map((k, v) => MapEntry(k, v * multiplier));
  }

  // เวลาอัปเกรด (วินาที)
  int get upgradeSeconds {
    if (remoteConfig != null && remoteConfig![buildingType] != null) {
      final config = remoteConfig![buildingType];
      final base = config['base_seconds'] ?? 300;
      return (base as num).toInt() * level;
    }
    const baseSeconds = {
      'sawmill': 180, // 3 นาที
      'smelter': 180,
      'rice_farm': 240,
      'distillery': 300,
      'house': 120,
      'tavern': 200,
      'shrine': 360,
      'barracks': 300,
      'elephant_camp': 600,
      'smithy': 400,
      'wall': 500,
'cannon': 450,
'watchtower': 350,
      'town_hall': 600,
    };
    final base = baseSeconds[buildingType] ?? 300;
    return base * level; // แต่ละ level นานขึ้นเรื่อยๆ
  }

  // town hall กำหนด cap อาคารและทหาร
  static int maxBuildingSlots(int townHallLevel) => 5 + (townHallLevel * 2);
  static int maxTroopCap(int townHallLevel) => 50 * townHallLevel;

  // population ที่เพิ่มจากอาคาร
  int get populationBonus {
    switch (buildingType) {
      case 'house':
        return 5 * level;
      case 'tavern':
        return 2 * level;
      default:
        return 0;
    }
  }

  // defense power ที่เพิ่มจากอาคาร
 int get defenseBonus {
  switch (buildingType) {
    case 'wall':
      const wallBonus = [0, 20, 35, 55, 80, 110];
      return wallBonus[level.clamp(0, 5)];
    case 'cannon': // ลด attack ศัตรู 5/10/18%
      return 0; // handle ใน SQL ไม่ใช่ defense point
    case 'watchtower':  return 15 * level;
    default:            return 0;
  }
}

  // production ต่อ tick (5 นาที)
  Map<String, int> get productionPerTick {
    if (remoteConfig != null && remoteConfig![buildingType] != null) {
      final config = remoteConfig![buildingType];
      final baseProd = config['base_prod_tick'] as Map<String, dynamic>?;
      final prodLvl = config['prod_tick_per_level'] as Map<String, dynamic>?;
      if (baseProd != null && baseProd.isNotEmpty) {
        final result = <String, int>{};
        baseProd.forEach((k, v) {
          final baseVal = (v as num).toInt();
          final lvlVal = prodLvl != null && prodLvl[k] != null
              ? (prodLvl[k] as num).toInt()
              : 0;
          result[k] = baseVal + (lvlVal * level);
        });
        return result;
      }
    }
    switch (buildingType) {
      case 'sawmill':
        return {'wood': 6 + (level * 3)}; // เยอะสุด
      case 'rice_farm':
        return {'rice': 6 + (level * 3)}; // เท่ากับไม้
      case 'smelter':
        return {'iron': 2 + level}; // น้อยกว่า
      case 'distillery':
        return {'liquor': 1 + level};
      default:
        return {};
    }
  }
}
