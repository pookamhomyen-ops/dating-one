import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/troop.dart';
import '../models/settlement.dart';

class TroopService {
  final SupabaseClient _supabase;
  TroopService(this._supabase);

  // ฝึกทหาร
  Future<void> trainTroops({
    required Troop troop,
    required Settlement settlement,
    required List<Troop> allTroops,
    required int amount,
  }) async {
    if (troop.isTraining) throw Exception('กำลังฝึกอยู่แล้ว');

    // เช็ค population cap
    final totalTroops = allTroops.fold(0, (sum, t) => sum + t.count);
    final maxTroops = settlement.maxTroops;
    if (totalTroops + amount > maxTroops) {
      throw Exception('ทหารเกิน cap ประชาชน (สูงสุด $maxTroops)');
    }

    // คำนวณต้นทุน
    final cost = troop.costPerUnit;
    final totalWood = (cost['wood'] ?? 0) * amount;
    final totalIron = (cost['iron'] ?? 0) * amount;

    if (settlement.wood < totalWood) throw Exception('ไม้ไม่พอ');
    if (settlement.iron < totalIron) throw Exception('เหล็กไม่พอ');

    // หักทรัพยากร
    await _supabase.from('game.settlements').update({
      'wood': settlement.wood - totalWood,
      'iron': settlement.iron - totalIron,
    }).eq('id', settlement.id);

    // คิว training
    final finishAt = DateTime.now().add(
      Duration(seconds: troop.trainingSeconds),
    );

    await _supabase.from('game.troops').update({
      'training_count': amount,
      'training_finish_at': finishAt.toIso8601String(),
    }).eq('id', troop.id);
  }

  // เช็คและ complete training ที่เสร็จแล้ว
  Future<Troop?> checkAndCompleteTraining(Troop troop) async {
    if (!troop.isTraining) return null;
    if (troop.trainingFinishAt == null) return null;
    if (DateTime.now().isBefore(troop.trainingFinishAt!)) return null;

    final data = await _supabase
        .from('game.troops')
        .update({
          'count': troop.count + troop.trainingCount,
          'training_count': 0,
          'training_finish_at': null,
        })
        .eq('id', troop.id)
        .select()
        .single();

    return Troop.fromJson(data);
  }
}