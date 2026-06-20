import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/game_service.dart';
import '../services/production_service.dart';
import '../services/happiness_service.dart';
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
  final mainClient = ref.watch(supabaseProvider);   // ดึง userId จาก mainClient
  final gameClient = ref.watch(gameSupabaseProvider); // query ผ่าน game schema
  final userId = mainClient.auth.currentUser?.id;
  if (userId == null) return null;

  final data = await gameClient
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

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final settlement = await ref.watch(settlementProvider.future);
  if (settlement == null) return [];

  final gameClient = ref.watch(gameSupabaseProvider);
  final data = await gameClient
      .from('notifications')
      .select()
      .eq('settlement_id', settlement.id)
      .order('created_at', ascending: false)
      .limit(30);

  return List<Map<String, dynamic>>.from(data);
});

final mapNodesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final settlement = await ref.watch(settlementProvider.future);
  if (settlement == null) return [];

  final gameClient = ref.watch(gameSupabaseProvider);
  final data = await gameClient
      .from('map_nodes')
      .select()
      .eq('owner_settlement_id', settlement.id);

  return List<Map<String, dynamic>>.from(data);
});

final offlineProductionProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final lastOnlineMs = prefs.getInt('last_online_at');
  final lastOnlineAt = lastOnlineMs != null
      ? DateTime.fromMillisecondsSinceEpoch(lastOnlineMs)
      : DateTime.now();

  await prefs.setInt('last_online_at', DateTime.now().millisecondsSinceEpoch);

  final settlement = await ref.watch(settlementProvider.future);
  if (settlement == null) return;

  final buildings = await ref.watch(buildingsProvider.future);
  if (buildings.isEmpty) return;

  final mainClient = ref.read(supabaseProvider);
  final gameClient = ref.read(gameSupabaseProvider);
  final service = GameService(mainClient);

  // Production
  final gained = ProductionService.calculateOfflineProduction(
    settlement: settlement,
    buildings: buildings,
    lastOnlineAt: lastOnlineAt,
  );

  if (gained.isNotEmpty) {
    await service.applyOfflineProduction(
      settlement: settlement,
      buildings: buildings,
      lastOnlineAt: lastOnlineAt,
    );

    // แจ้งเตือน production
    final parts = <String>[];
    if ((gained['wood']   ?? 0) > 0) parts.add('🪵${gained['wood']}');
    if ((gained['iron']   ?? 0) > 0) parts.add('⚙️${gained['iron']}');
    if ((gained['rice']   ?? 0) > 0) parts.add('🌾${gained['rice']}');
    if ((gained['liquor'] ?? 0) > 0) parts.add('🍶${gained['liquor']}');
    if (parts.isNotEmpty) {
      await gameClient.from('notifications').insert({
        'settlement_id': settlement.id,
        'icon': '🏭',
        'text': 'ผลิตทรัพยากรระหว่างออฟไลน์: ${parts.join(' ')}',
        'accent_color': '#5DCAA5',
      });
    }
  }

  // Happiness
  final newHappiness = HappinessService.calculateHappiness(
    settlement: settlement,
    buildings: buildings,
    wasAttackedRecently: false,
  );

  if (newHappiness != settlement.happiness) {
    await gameClient.from('settlements').update({
      'happiness': newHappiness,
      'happiness_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', settlement.id);

    if (newHappiness < 40 && settlement.happiness >= 40) {
      await gameClient.from('notifications').insert({
        'settlement_id': settlement.id,
        'icon': '😠',
        'text': 'ประชาชนเริ่มไม่พอใจ! happiness ลดลงเหลือ $newHappiness%',
        'accent_color': '#F0997B',
      });
    }
  }

  ref.invalidate(settlementProvider);
  ref.invalidate(notificationsProvider);
});