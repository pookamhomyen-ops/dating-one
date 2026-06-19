import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/settlement.dart';
import '../models/building.dart';
import '../models/troop.dart';

final supabaseProvider = Provider((ref) => Supabase.instance.client);

final settlementProvider = FutureProvider<Settlement?>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  final data = await supabase
      .from('game.settlements')
      .select()
      .eq('player_id', userId)
      .maybeSingle();

  return data != null ? Settlement.fromJson(data) : null;
});

final buildingsProvider = FutureProvider<List<Building>>((ref) async {
  final settlement = await ref.watch(settlementProvider.future);
  if (settlement == null) return [];

  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
      .from('game.buildings')
      .select()
      .eq('settlement_id', settlement.id);

  return (data as List).map((e) => Building.fromJson(e)).toList();
});

final troopsProvider = FutureProvider<List<Troop>>((ref) async {
  final settlement = await ref.watch(settlementProvider.future);
  if (settlement == null) return [];

  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
      .from('game.troops')
      .select()
      .eq('settlement_id', settlement.id);

  return (data as List).map((e) => Troop.fromJson(e)).toList();
});

final gameRefreshProvider = StateProvider<int>((ref) => 0);