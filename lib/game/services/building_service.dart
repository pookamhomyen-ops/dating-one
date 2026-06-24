import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/building.dart';
import '../models/settlement.dart';

class BuildingService {
  final SupabaseClient _supabase;
  BuildingService(this._supabase);

  // สร้างอาคารใหม่
  Future<Building> constructBuilding({
    required Settlement settlement,
    required String buildingType,
  }) async {
    // หักทรัพยากร
    final tempBuilding = Building(
      id: '',
      settlementId: settlement.id,
      buildingType: buildingType,
      level: 1,
      isUpgrading: false,
      createdAt: DateTime.now(),
    );
    final cost = tempBuilding.upgradeCost;
    await _deductResources(settlement, cost);

    // สุ่ม house_variant ถ้าเป็นบ้าน
    final variant = buildingType == 'house'
        ? (DateTime.now().millisecondsSinceEpoch % 5) + 1
        : null;

    final data = await _supabase
        .from('buildings')
        .insert({
          'settlement_id': settlement.id,
          'building_type': buildingType,
          'level': 1,
          'house_variant': ?variant,
        })
        .select()
        .single();

    return Building.fromJson(data);
  }

  // เริ่ม upgrade อาคาร
  Future<void> startUpgrade({
    required Building building,
    required Settlement settlement,
  }) async {
    if (building.isUpgrading) throw Exception('อาคารนี้กำลัง upgrade อยู่แล้ว');
    if (building.level >= 5) throw Exception('อาคารนี้ถึงระดับสูงสุดแล้ว');

    final cost = building.upgradeCost;
    await _deductResources(settlement, cost);

    final finishAt = DateTime.now().add(
      Duration(seconds: building.upgradeSeconds),
    );

    await _supabase
        .from('buildings')
        .update({
          'is_upgrading': true,
          'upgrade_finish_at': finishAt.toIso8601String(),
        })
        .eq('id', building.id);
  }

  // เช็คและ complete upgrade ที่เสร็จแล้ว
  Future<Building?> checkAndCompleteUpgrade(Building building) async {
    if (!building.isUpgrading) return null;
    if (!building.upgradeComplete) return null;

    final data = await _supabase
        .from('buildings')
        .update({
          'level': building.level + 1,
          'is_upgrading': false,
          'upgrade_finish_at': null,
        })
        .eq('id', building.id)
        .select()
        .single();

    return Building.fromJson(data);
  }

  Future<void> _deductResources(
    Settlement settlement,
    Map<String, int> cost,
  ) async {
    final updates = <String, dynamic>{};
    if ((cost['wood'] ?? 0) > 0) {
      if (settlement.wood < cost['wood']!) throw Exception('ไม้ไม่พอ');
      updates['wood'] = settlement.wood - cost['wood']!;
    }
    if ((cost['iron'] ?? 0) > 0) {
      if (settlement.iron < cost['iron']!) throw Exception('เหล็กไม่พอ');
      updates['iron'] = settlement.iron - cost['iron']!;
    }

    await _supabase
        .from('settlements')
        .update(updates)
        .eq('id', settlement.id);
  }
}