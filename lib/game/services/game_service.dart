import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../models/settlement.dart';
import '../models/building.dart';
import '../services/production_service.dart';

class GameService {
  final SupabaseClient _supabase; // รับตัวแปร Supabase.instance.client (ตัวหลัก) เข้ามา
  GameService(this._supabase);

  Future<Settlement> createSettlement({
    required String name,
    required int mapX,
    required int mapY,
  }) async {
    // ดึงค่า userId จาก Client หลักที่ล็อกอินอยู่ (ได้ค่าชัวร์ ไม่เป็น null แน่นอน)
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('ยังไม่ได้ล็อกอิน');

    // บันทึกโปรไฟล์ลงตาราง players ใน schema game
    await _supabase.schema('game').from('players').upsert({
      'id': userId,
      'display_name': name,
    });

    // บันทึกข้อมูลลงตาราง settlements ใน schema game
    final data = await _supabase
        .schema('game')
        .from('settlements')
        .insert({
          'player_id': userId,
          'name': name,
          'map_x': mapX,
          'map_y': mapY,
        })
        .select()
        .single();

    final settlement = Settlement.fromJson(data);
    await _initStarterBuildings(settlement.id);
    await _initTroopSlots(settlement.id);
    await _initMapNodes(settlement.id, mapX, mapY);
    return settlement;
  }

  Future<void> _initStarterBuildings(String settlementId) async {
    final starterBuildings = [
      {'building_type': 'town_hall', 'level': 1},
      {'building_type': 'sawmill',   'level': 1},
      {'building_type': 'smelter',   'level': 1},
      {'building_type': 'rice_farm', 'level': 1},
      {'building_type': 'barracks',  'level': 1},
      {'building_type': 'house',     'level': 1, 'house_variant': 1},
    ];

    for (final b in starterBuildings) {
      await _supabase.schema('game').from('buildings').insert({
        ...b,
        'settlement_id': settlementId,
      });
    }
  }

  Future<void> _initMapNodes(
    String settlementId, int centerX, int centerY) async {
    final rng = Random();
    final nodes = [
      {
        'node_type': 'bandit',
        'defense_power': 30 + rng.nextInt(40),
        'loot_pool': {'wood': 20, 'iron': 10, 'rice': 15},
        'offset': [_rngOffset(rng), _rngOffset(rng)],
      },
      {
        'node_type': 'forest',
        'defense_power': 10 + rng.nextInt(20),
        'loot_pool': {'wood': 50},
        'offset': [_rngOffset(rng), _rngOffset(rng)],
      },
      {
        'node_type': 'iron_mine',
        'defense_power': 10 + rng.nextInt(20),
        'loot_pool': {'iron': 50},
        'offset': [_rngOffset(rng), _rngOffset(rng)],
      },
      {
        'node_type': 'npc_settlement',
        'defense_power': 60 + rng.nextInt(40),
        'loot_pool': {'wood': 30, 'iron': 20, 'rice': 25, 'liquor': 10},
        'offset': [_rngOffset(rng), _rngOffset(rng)],
      },
    ];

    for (final n in nodes) {
      final offset = n['offset'] as List;
      await _supabase.schema('game').from('map_nodes').insert({
        'node_type': n['node_type'],
        'map_x': (centerX + offset[0]).clamp(1, 100),
        'map_y': (centerY + offset[1]).clamp(1, 100),
        'defense_power': n['defense_power'],
        'loot_pool': n['loot_pool'],
        'owner_settlement_id': settlementId,
      });
    }
  }

  // สุ่ม offset ±5 ถึง ±15 ไม่ให้ชนกับชุมนุม
  int _rngOffset(Random rng) {
    final sign = rng.nextBool() ? 1 : -1;
    return sign * (5 + rng.nextInt(11));
  }

  Future<void> _initTroopSlots(String settlementId) async {
    final troopTypes = [
      'swordsman', 'archer', 'spearman', 'cavalry', 'elephant'
    ];
    for (final type in troopTypes) {
      await _supabase.schema('game').from('troops').insert({
        'settlement_id': settlementId,
        'troop_type': type,
        'count': 0,
      });
    }
  }

  Future<void> updateResources(
    String settlementId, {
    int? wood, int? iron, int? rice, int? liquor,
  }) async {
    final updates = <String, dynamic>{};
    if (wood != null)   updates['wood'] = wood;
    if (iron != null)   updates['iron'] = iron;
    if (rice != null)   updates['rice'] = rice;
    if (liquor != null) updates['liquor'] = liquor;

    await _supabase
        .schema('game')
        .from('settlements')
        .update(updates)
        .eq('id', settlementId);
  }

  // คำนวณ offline production แล้วอัพ DB ในครั้งเดียว
  Future<Settlement?> applyOfflineProduction({
    required Settlement settlement,
    required List<Building> buildings,
    required DateTime lastOnlineAt,
  }) async {
    final gained = ProductionService.calculateOfflineProduction(
      settlement: settlement,
      buildings: buildings,
      lastOnlineAt: lastOnlineAt,
    );
    if (gained.isEmpty) return null;

    final newWood   = settlement.wood   + (gained['wood']   ?? 0);
    final newIron   = settlement.iron   + (gained['iron']   ?? 0);
    final newRice   = settlement.rice   + (gained['rice']   ?? 0);
    final newLiquor = settlement.liquor + (gained['liquor'] ?? 0);

    await updateResources(
      settlement.id,
      wood: newWood,
      iron: newIron,
      rice: newRice,
      liquor: newLiquor,
    );

    return settlement.copyWith(
      wood: newWood, iron: newIron,
      rice: newRice, liquor: newLiquor,
    );
  }
}