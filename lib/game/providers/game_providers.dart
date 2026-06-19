import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/settlement.dart';
import '../models/building.dart';
import '../models/troop.dart';
import '../../constants.dart';

// 1. Client หลักของแอป
final supabaseProvider = Provider((ref) => Supabase.instance.client);

// 2. ✅ แก้ไขตรงนี้: ดึงค่า Client หลักมา แล้วนำมาครอบด้วยออปชันกำหนด Schema คืนค่ากลับไปเป็น SupabaseClient เหมือนเดิม
final gameSupabaseProvider = Provider<SupabaseClient>((ref) {
  final mainClient = ref.watch(supabaseProvider);
  final currentSession = mainClient.auth.currentSession;
  
  return SupabaseClient(
    SupabaseConstants.url,       // ดึงค่า URL หลักของระบบ
    SupabaseConstants.anonKey,   // ดึงค่า Anon Key หลักของระบบ
    postgrestOptions: const PostgrestClientOptions(schema: 'game'),
    headers: currentSession != null
        ? {
            'Authorization': 'Bearer ${currentSession.accessToken}',
            'apikey': SupabaseConstants.anonKey,
          }
        : {},
  );
});

final settlementProvider = FutureProvider<Settlement?>((ref) async {
  final supabase = ref.watch(gameSupabaseProvider); // เรียกผ่านตัวล็อก schema
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  final data = await supabase
      .from('settlements')
      .select()
      .eq('player_id', userId)
      .maybeSingle();

  return data != null ? Settlement.fromJson(data) : null;
});

final buildingsProvider = FutureProvider<List<Building>>((ref) async {
  final settlement = await ref.watch(settlementProvider.future);
  if (settlement == null) return [];

  final supabase = ref.watch(gameSupabaseProvider);
  final data = await supabase
      .from('buildings')
      .select()
      .eq('settlement_id', settlement.id);

  return (data as List).map((e) => Building.fromJson(e)).toList();
});

final troopsProvider = FutureProvider<List<Troop>>((ref) async {
  final settlement = await ref.watch(settlementProvider.future);
  if (settlement == null) return [];

  final supabase = ref.watch(gameSupabaseProvider);
  final data = await supabase
      .from('troops')
      .select()
      .eq('settlement_id', settlement.id);

  return (data as List).map((e) => Troop.fromJson(e)).toList();
});

final gameRefreshProvider = StateProvider<int>((ref) => 0);