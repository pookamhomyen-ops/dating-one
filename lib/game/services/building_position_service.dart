import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/building_position.dart';

class BuildingPositionService {
  final SupabaseClient _supabase;

  BuildingPositionService(this._supabase);

  Future<List<BuildingPosition>> getPositions(String settlementId) async {
    final response = await _supabase
        .from('building_positions')
        .select()
        .eq('settlement_id', settlementId);
    return (response as List).map((e) => BuildingPosition.fromJson(e)).toList();
  }

  Future<void> savePositions(List<BuildingPosition> positions) async {
    if (positions.isEmpty) return;
    final data = positions.map((p) => {
      'settlement_id': p.settlementId,
      'building_id': p.buildingId,
      'pos_x': p.posX,
      'pos_y': p.posY,
    }).toList();
    await _supabase.from('building_positions').upsert(data, onConflict: 'settlement_id,building_id');
  }
}