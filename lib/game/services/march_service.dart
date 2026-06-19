import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/march.dart';
import '../models/settlement.dart';
import '../models/troop.dart';

class MarchService {
  final SupabaseClient _supabase;
  MarchService(this._supabase);

  // ส่งกองทัพไปโจมตีโหนด
  Future<March> sendAttack({
    required Settlement settlement,
    required String targetNodeId,
    required Map<String, int> troops,
    required int travelMinutes,
  }) async {
    await _deductTroops(settlement.id, troops);

    final now = DateTime.now();
    final arriveAt = now.add(Duration(minutes: travelMinutes));

    final data = await _supabase
        .from('march_queues')
        .insert({
          'settlement_id': settlement.id,
          'march_type': 'attack',
          'target_node_id': targetNodeId,
          'troops_sent': troops,
          'depart_at': now.toIso8601String(),
          'arrive_at': arriveAt.toIso8601String(),
          'status': 'marching',
        })
        .select()
        .single();

    return March.fromJson(data);
  }

  // resolve การรบเมื่อกองทัพถึงที่หมาย
  Future<Map<String, dynamic>> resolveBattle({
    required March march,
    required int nodeDefensePower,
    required Map<String, dynamic> nodeLootPool,
  }) async {
    final attackPower = march.totalAttackPower;
    final isVictory = attackPower > nodeDefensePower;

    Map<String, int> loot = {};
    Map<String, int> troopsLost = {};

    if (isVictory) {
      // สุ่ม loot จาก loot_pool
      loot = _rollLoot(nodeLootPool);
      // สูญเสียทหารน้อย (~10-20%)
      troopsLost = _calculateLosses(march.troopsSent, 0.15);
    } else {
      // แพ้ — สูญเสียทหารเยอะ (~40-50%)
      troopsLost = _calculateLosses(march.troopsSent, 0.45);
    }

    // เวลาเดินทางกลับ (เท่ากับเวลาไป)
    final travelTime = march.arriveAt.difference(march.departAt);
    final returnAt = DateTime.now().add(travelTime);

    // อัปเดต march → returning
    await _supabase.from('march_queues').update({
      'status': 'returning',
      'march_type': 'return',
      'loot': loot,
      'arrive_at': returnAt.toIso8601String(),
    }).eq('id', march.id);

    return {
      'victory': isVictory,
      'loot': loot,
      'troops_lost': troopsLost,
    };
  }

  // รับทหารและ loot กลับเมื่อเดินทางกลับถึง
  Future<void> completeMarch({
    required March march,
    required Settlement settlement,
    required List<Troop> currentTroops,
  }) async {
    // คืนทหารที่รอดกลับมา
    final survivingTroops = march.troopsSent;
    for (final entry in survivingTroops.entries) {
      final troop = currentTroops
          .where((t) => t.troopType == entry.key)
          .firstOrNull;
      if (troop == null) continue;

      await _supabase.from('troops').update({
        'count': troop.count + entry.value,
      }).eq('id', troop.id);
    }

    // เพิ่ม loot เข้าคลัง
    if (march.loot.isNotEmpty) {
      await _supabase.from('settlements').update({
        'wood':   settlement.wood  + (march.loot['wood']   ?? 0),
        'iron':   settlement.iron  + (march.loot['iron']   ?? 0),
        'rice':   settlement.rice  + (march.loot['rice']   ?? 0),
        'liquor': settlement.liquor + (march.loot['liquor'] ?? 0),
      }).eq('id', settlement.id);
    }

    // mark completed
    await _supabase.from('march_queues').update({
      'status': 'completed',
    }).eq('id', march.id);
  }

  // ดึง march ที่กำลัง active อยู่
  Future<List<March>> getActiveMarches(String settlementId) async {
    final data = await _supabase
        .from('march_queues')
        .select()
        .eq('settlement_id', settlementId)
        .neq('status', 'completed')
        .order('arrive_at');

    return (data as List).map((e) => March.fromJson(e)).toList();
  }

  Map<String, int> _rollLoot(Map<String, dynamic> lootPool) {
    final loot = <String, int>{};
    lootPool.forEach((key, value) {
      if (value is List && value.length == 2) {
        final min = value[0] as int;
        final max = value[1] as int;
        loot[key] = min + (DateTime.now().millisecondsSinceEpoch % (max - min + 1));
      }
    });
    return loot;
  }

  Map<String, int> _calculateLosses(
    Map<String, int> troops,
    double lossRate,
  ) {
    return troops.map(
      (type, count) => MapEntry(
        type,
        (count * lossRate).round(),
      ),
    );
  }

  Future<void> _deductTroops(
    String settlementId,
    Map<String, int> troops,
  ) async {
    for (final entry in troops.entries) {
      await _supabase.rpc('deduct_troops', params: {
        'p_settlement_id': settlementId,
        'p_troop_type': entry.key,
        'p_amount': entry.value,
      });
    }
  }
}