import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/settlement.dart';

class GameService {
  final SupabaseClient _supabase;
  GameService(this._supabase);

  Future<Settlement> createSettlement({
    required String name,
    required int mapX,
    required int mapY,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    await _supabase.from('game.players').upsert({
      'id': userId,
      'display_name': name,
    });

    final data = await _supabase
        .from('game.settlements')
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
    return settlement;
  }

  Future<void> _initStarterBuildings(String settlementId) async {
    final starterBuildings = [
      {'building_type': 'town_hall', 'level': 1},
      {'building_type': 'sawmill',   'level': 1},
      {'building_type': 'rice_farm', 'level': 1},
      {'building_type': 'barracks',  'level': 1},
      {'building_type': 'house',     'level': 1, 'house_variant': 1},
    ];

    for (final b in starterBuildings) {
      await _supabase.from('game.buildings').insert({
        ...b,
        'settlement_id': settlementId,
      });
    }
  }

  Future<void> _initTroopSlots(String settlementId) async {
    final troopTypes = [
      'swordsman', 'archer', 'spearman', 'cavalry', 'elephant'
    ];
    for (final type in troopTypes) {
      await _supabase.from('game.troops').insert({
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
        .from('game.settlements')
        .update(updates)
        .eq('id', settlementId);
  }
}