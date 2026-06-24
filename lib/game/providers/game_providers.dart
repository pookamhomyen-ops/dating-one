import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/game_service.dart';
import '../services/production_service.dart';
import '../services/happiness_service.dart';
import '../models/settlement.dart';
import '../models/building.dart';
import '../models/troop.dart';
import '../models/caravan.dart';
import '../models/march.dart';
import '../../constants.dart';
import 'package:flutter/painting.dart';
import '../models/building_position.dart';
import '../services/building_position_service.dart';


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

  // โหลด configurations จากระบบแอดมิน (DB)
  try {
    final configs = await gameClient.from('game_configs').select();
    for (final config in configs) {
      final key = config['key'];
      final value = config['value'];
      if (key == 'buildings') {
        Building.remoteConfig = value as Map<String, dynamic>?;
      } else if (key == 'troops') {
        Troop.remoteConfig = value as Map<String, dynamic>?;
      } else if (key == 'resources') {
        final resVal = value as Map<String, dynamic>?;
        if (resVal != null) {
          ProductionService.tickDurationMinutes = (resVal['tick_duration_minutes'] as num?)?.toInt() ?? 5;
          ProductionService.offlineCapMinutes = (resVal['offline_cap_minutes'] as num?)?.toInt() ?? 480;
        }
      }
    }
  } catch (e) {
    print('Failed to load remote game configurations: $e');
  }

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

// ศัตรูใน 24 ชั่วโมงล่าสุด
final recentEnemiesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final settlement = await ref.watch(settlementProvider.future);
  if (settlement == null) return [];

  final gameClient = ref.watch(gameSupabaseProvider);
  final since = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();

  final data = await gameClient
      .from('enemies')
      .select()
      .eq('settlement_id', settlement.id)
      .gte('attacked_at', since)
      .order('attacked_at', ascending: false);

  return List<Map<String, dynamic>>.from(data);
});

// ประวัติศัตรูทั้งหมด
final enemyHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final settlement = await ref.watch(settlementProvider.future);
  if (settlement == null) return [];

  final gameClient = ref.watch(gameSupabaseProvider);
  final data = await gameClient
      .from('enemies')
      .select()
      .eq('settlement_id', settlement.id)
      .order('attacked_at', ascending: false)
      .limit(50);

  return List<Map<String, dynamic>>.from(data);
});

final seasonProvider = FutureProvider<String>((ref) async {
  final gameClient = ref.watch(gameSupabaseProvider);
  final data = await gameClient
      .from('season')
      .select()
      .eq('id', 1)
      .single();

  final season = data['current_season'] as String;
  final startedAt = DateTime.parse(data['started_at']);
  final now = DateTime.now();
  final daysPassed = now.difference(startedAt).inDays;

  // วนรอบ: ร้อน 3 วัน, ฝน 1 วัน, หนาว 1 วัน = 5 วัน/รอบ
  const cycle = [
    'summer', 'summer', 'summer', 'rain', 'winter',
  ];
  final currentSeason = cycle[daysPassed % cycle.length];

  // อัพเดท DB ถ้าฤดูเปลี่ยน
  if (currentSeason != season) {
    await gameClient.from('season').update({
      'current_season': currentSeason,
    }).eq('id', 1);
  }

  return currentSeason;
});

final activeMarchesProvider = FutureProvider<List<March>>((ref) async {
  final settlement = await ref.watch(settlementProvider.future);
  if (settlement == null) return [];

  final gameClient = ref.watch(gameSupabaseProvider);
  final data = await gameClient
      .from('march_queues')
      .select()
      .eq('settlement_id', settlement.id)
      .neq('status', 'completed')
      .order('arrive_at');

  return List<Map<String, dynamic>>.from(data)
      .map((e) => March.fromJson(e))
      .toList();
});

// viewport center สำหรับ lazy load
final mapViewportProvider = StateProvider<Offset>((ref) => Offset.zero);

final nearbySettlementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final settlement = await ref.watch(settlementProvider.future);
  if (settlement == null) return [];

  final viewport = ref.watch(mapViewportProvider);
  final centerX = viewport == Offset.zero ? settlement.mapX : viewport.dx.toInt();
  final centerY = viewport == Offset.zero ? settlement.mapY : viewport.dy.toInt();

  final mainClient = ref.watch(supabaseProvider);
  final data = await mainClient.rpc('game.get_nearby_settlements', params: {
    'p_center_x': centerX,
    'p_center_y': centerY,
    'p_radius': 30,
  });

  return List<Map<String, dynamic>>.from(data ?? []);
});

// town hall level
final townHallLevelProvider = Provider<int>((ref) {
  final buildings = ref.watch(buildingsProvider).valueOrNull ?? [];
  final th = buildings.where((b) => b.buildingType == 'town_hall').firstOrNull;
  return th?.level ?? 1;
});

// defense power รวมของชุมนุม
final settlementDefenseProvider = Provider<int>((ref) {
  final buildings = ref.watch(buildingsProvider).valueOrNull ?? [];
  int defense = 50; // base
  for (final b in buildings) {
    defense += b.defenseBonus;
  }
  return defense;
});

// population สูงสุดจากบ้านเรือน
final maxPopulationProvider = Provider<int>((ref) {
  final buildings = ref.watch(buildingsProvider).valueOrNull ?? [];
  int pop = 50; // base
  for (final b in buildings) {
    pop += b.populationBonus;
  }
  return pop;
});

final marchHistoryProvider = FutureProvider<List<March>>((ref) async {
  final settlement = await ref.watch(settlementProvider.future);
  if (settlement == null) return [];

  final gameClient = ref.watch(gameSupabaseProvider);
  final data = await gameClient
      .from('march_queues')
      .select()
      .eq('settlement_id', settlement.id)
      .eq('status', 'completed')
      .order('arrive_at', ascending: false)
      .limit(10);

  return List<Map<String, dynamic>>.from(data)
      .map((e) => March.fromJson(e))
      .toList();
});

// ดึง settlement ของคู่แมทช์
final matchSettlementProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final mainClient = ref.watch(supabaseProvider);
  final userId = mainClient.auth.currentUser?.id;
  if (userId == null) return null;

  // ดึง match จาก public.matches
  final matchData = await mainClient
      .from('matches')
      .select()
      .or('user_a_id.eq.$userId,user_b_id.eq.$userId')
      .order('matched_at', ascending: false)
      .limit(1)
      .maybeSingle();

  if (matchData == null) return null;

  // หา partner id
  final partnerId = matchData['user_a_id'] == userId
      ? matchData['user_b_id']
      : matchData['user_a_id'];

  // ดึง settlement ของ partner
  final gameClient = ref.watch(gameSupabaseProvider);
  final settlement = await gameClient
      .from('settlements')
      .select()
      .eq('player_id', partnerId)
      .maybeSingle();

  return settlement;
});

// ดึง caravans ที่ active (ส่งออกและรับเข้า)
final caravansProvider = FutureProvider<List<Caravan>>((ref) async {
  final settlement = await ref.watch(settlementProvider.future);
  if (settlement == null) return [];

  final gameClient = ref.watch(gameSupabaseProvider);
  final data = await gameClient
      .from('caravans')
      .select()
      .or('from_settlement_id.eq.${settlement.id},to_settlement_id.eq.${settlement.id}')
      .neq('status', 'arrived')
      .order('arrive_at');

  return List<Map<String, dynamic>>.from(data)
      .map((e) => Caravan.fromJson(e))
      .toList();
});

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

final buildingPositionServiceProvider = Provider<BuildingPositionService>((ref) {
  return BuildingPositionService(ref.read(gameSupabaseProvider));
});

final buildingPositionsProvider = FutureProvider<List<BuildingPosition>>((ref) async {
  final settlement = ref.watch(settlementProvider).value;
  if (settlement == null) return [];
  final service = ref.read(buildingPositionServiceProvider);
  return service.getPositions(settlement.id);
});