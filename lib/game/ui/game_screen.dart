import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../models/caravan.dart';
import '../services/building_service.dart';
import '../services/troop_service.dart';
import '../services/march_service.dart';
import '../services/production_service.dart';
import 'map_tab.dart';
import 'building_tab.dart';
import 'troop_tab.dart';
import 'caravan_tab.dart';
import 'notification_tab.dart';
import 'enemy_tab.dart';
import 'package:supabase_flutter/supabase_flutter.dart';




class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  int _currentTab = 0;
  Timer? _ticker;
  Timer? _completeChecker;
  RealtimeChannel? _realtimeChannel;
  DateTime _lastProductionTick = DateTime.now();

  final _tabs = const [
    _TabItem(label: 'แผนที่',    icon: Icons.map_outlined),
    _TabItem(label: 'อาคาร',     icon: Icons.home_work_outlined),
    _TabItem(label: 'ทหาร',      icon: Icons.shield_outlined),
    _TabItem(label: 'คาราวาน',   icon: Icons.local_shipping_outlined),
    _TabItem(label: 'แจ้งเตือน', icon: Icons.notifications_outlined, hasBadge: true),
  ];

  void switchTab(int index) {
    setState(() => _currentTab = index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(offlineProductionProvider));

    // rebuild ทุก 1 วินาที เพื่อให้ countdown สด + เช็ค production tick
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _checkProductionTick();
    });

    // เช็ค complete upgrade/training ทุก 10 วินาที
    _completeChecker = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkCompletes();
    });

    // Realtime — รอให้ settlement โหลดก่อนแล้วค่อย subscribe
    _subscribeRealtime();
  }

  Future<void> _subscribeRealtime() async {
    final settlement = await ref.read(settlementProvider.future);
    if (settlement == null) return;

    final client = ref.read(supabaseProvider);

    _realtimeChannel = client
        .channel('march_incoming_${settlement.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'game',
          table: 'march_queues',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'target_settlement_id',
            value: settlement.id,
          ),
          callback: (payload) async {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚔️ มีกองทัพกำลังบุกชุมนุมของคุณ!'),
                backgroundColor: Color(0xFF993C1D),
                duration: Duration(seconds: 5),
              ),
            );

            // บันทึกศัตรู
            try {
              final newRow = payload.newRecord;
              final attackerSettlementId = newRow['settlement_id'] as String?;
              if (attackerSettlementId != null) {
                final settlement = ref.read(settlementProvider).valueOrNull;
                if (settlement != null) {
                  final gameClient = ref.read(gameSupabaseProvider);

                  // ดึงชื่อชุมนุมของผู้บุก
                  final attackerData = await gameClient
                      .from('settlements')
                      .select('name')
                      .eq('id', attackerSettlementId)
                      .maybeSingle();

                  final attackerName = attackerData?['name'] ?? 'ไม่ทราบชื่อ';
                  await gameClient.from('enemies').insert({
                    'settlement_id': settlement.id,
                    'enemy_settlement_id': attackerSettlementId,
                    'enemy_name': attackerName,
                    'attacked_at': DateTime.now().toIso8601String(),
                  });

                  // insert notification ถูกโจมตี
                  await gameClient.from('notifications').insert({
                    'settlement_id': settlement.id,
                    'icon': '⚔️',
                    'text': '🚨 $attackerName กำลังบุกชุมนุมของคุณ! เตรียมรับมือ!',
                    'accent_color': '#993C1D',
                    'is_read': false,
                  });
                  ref.invalidate(recentEnemiesProvider);
                  ref.invalidate(notificationsProvider);
                }
              }
            } catch (_) {}

            ref.invalidate(notificationsProvider);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'game',
          table: 'caravans',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'to_settlement_id',
            value: settlement.id,
          ),
          callback: (payload) {
            if (!mounted) return;
            // มีคาราวานส่งมาให้!
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🚢 คาราวานจากแมทช์กำลังมา!'),
                backgroundColor: Color(0xFF854F0B),
                duration: Duration(seconds: 4),
              ),
            );
            ref.invalidate(caravansProvider);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _completeChecker?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _checkCompletes() async {
    final buildings  = ref.read(buildingsProvider).valueOrNull ?? [];
    final troops     = ref.read(troopsProvider).valueOrNull ?? [];
    final settlement = ref.read(settlementProvider).valueOrNull;
    final gameClient = ref.read(gameSupabaseProvider);
    final mainClient = ref.read(supabaseProvider);

    bool changed = false;

    // เช็ค building upgrade
    for (final b in buildings) {
      if (b.isUpgrading && b.upgradeComplete) {
        await BuildingService(gameClient).checkAndCompleteUpgrade(b);
        await gameClient.from('notifications').insert({
          'settlement_id': b.settlementId,
          'icon': '🏗️',
          'text': 'อัปเกรด ${b.displayName} → Lv.${b.level + 1} เสร็จแล้ว!',
          'accent_color': '#AFA9EC',
          'is_read': false,
        });
        changed = true;
      }
    }

    // เช็ค troop training
    for (final t in troops) {
      if (t.isTraining && t.trainingTimeRemaining == Duration.zero) {
        await TroopService(gameClient).checkAndCompleteTraining(t);
        await gameClient.from('notifications').insert({
          'settlement_id': t.settlementId,
          'icon': '⚔️',
          'text': 'ฝึก${t.displayName} ${t.trainingCount} คน เสร็จแล้ว!',
          'accent_color': '#FAC775',
          'is_read': false,
        });
        changed = true;
      }
    }

    // เช็ค march ที่ถึงที่หมายแล้ว
    if (settlement != null) {
      final marchService = MarchService(gameClient);
      final marches = await marchService.getActiveMarches(settlement.id);

      for (final march in marches) {
        if (!march.hasArrived) continue;

        if (march.marchType == 'attack') {
          // ดึงข้อมูลโหนด
          final nodeData = await gameClient
              .from('map_nodes')
              .select()
              .eq('id', march.targetNodeId!)
              .maybeSingle();
          if (nodeData == null) continue;

          final result = await marchService.resolveBattle(
            march: march,
            nodeDefensePower: nodeData['defense_power'] as int,
            nodeLootPool: nodeData['loot_pool'] as Map<String, dynamic>,
          );

          final victory = result['victory'] as bool;
          final loot = result['loot'] as Map<String, int>;
          final lootText = loot.entries
              .map((e) => '${_resIcon(e.key)}${e.value}')
              .join(' ');

          await gameClient.from('notifications').insert({
            'settlement_id': settlement.id,
            'icon': victory ? '🏆' : '💀',
            'text': victory
                ? 'ชนะการรบ! ได้รับ $lootText'
                : 'แพ้การรบ กองทัพกำลังถอยกลับ',
            'accent_color': victory ? '#5DCAA5' : '#F0997B',
            'is_read': false,
          });
          changed = true;

        } else if (march.marchType == 'return') {
          // กองทัพกลับถึงแล้ว
          await marchService.completeMarch(
            march: march,
            settlement: settlement,
            currentTroops: troops,
          );
          final lootText = march.loot.entries
              .map((e) => '${_resIcon(e.key)}${e.value}')
              .join(' ');
          if (march.loot.isNotEmpty) {
            await gameClient.from('notifications').insert({
              'settlement_id': settlement.id,
              'icon': '🚩',
              'text': 'กองทัพกลับถึงแล้ว! นำของกลับมา $lootText',
              'accent_color': '#5DCAA5',
              'is_read': false,
            });
          }
          changed = true;
        }
      }
    }

    // caravan resolve โดย pg_cron แล้ว — แค่ invalidate provider
    if (settlement != null) {
      ref.invalidate(caravansProvider);
    }

    if (changed && mounted) {
      ref.invalidate(buildingsProvider);
      ref.invalidate(troopsProvider);
      ref.invalidate(settlementProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(caravansProvider);
      ref.invalidate(activeMarchesProvider);
      ref.invalidate(marchHistoryProvider);
    }
  }

  Future<void> _checkProductionTick() async {
    final now = DateTime.now();
    if (now.difference(_lastProductionTick).inMinutes < 5) return;
    _lastProductionTick = now;

    final settlement = ref.read(settlementProvider).valueOrNull;
    final buildings  = ref.read(buildingsProvider).valueOrNull ?? [];
    if (settlement == null) return;

    final gameClient = ref.read(gameSupabaseProvider);
    final updates = <String, dynamic>{};

    // Production
    if (buildings.isNotEmpty) {
      final gained = ProductionService.calculateOfflineProduction(
        settlement: settlement,
        buildings: buildings,
        lastOnlineAt: now.subtract(const Duration(minutes: 5)),
      );
      if (gained.isNotEmpty) {
        updates['wood']   = settlement.wood   + (gained['wood']   ?? 0);
        updates['iron']   = settlement.iron   + (gained['iron']   ?? 0);
        updates['rice']   = settlement.rice   + (gained['rice']   ?? 0);
        updates['liquor'] = settlement.liquor + (gained['liquor'] ?? 0);
      }
    }

    // Population growth — เพิ่มทีละ 1 ต่อ tick ถ้า happiness >= 40
    // และยังไม่ถึง maxPopulation
    final maxPop = ref.read(maxPopulationProvider);
    if (settlement.happiness >= 40 &&
        settlement.population < maxPop) {
      updates['population'] = settlement.population + 1;
      updates['max_population'] = maxPop;
    } else if (settlement.population > maxPop) {
      // บ้านถูกทำลาย ประชากรเกิน cap
      updates['population'] = maxPop;
      updates['max_population'] = maxPop;
    } else {
      // อัพเดท max_population ให้ตรงกับบ้านที่สร้างใหม่
      updates['max_population'] = maxPop;
    }

    if (updates.isNotEmpty) {
      await gameClient
          .from('settlements')
          .update(updates)
          .eq('id', settlement.id);
      if (mounted) ref.invalidate(settlementProvider);
    }
  }

  String _resIcon(String res) {
    const icons = {
      'wood': '🪵', 'iron': '⚙️', 'rice': '🌾', 'liquor': '🍶'
    };
    return icons[res] ?? res;
  }

  @override
  Widget build(BuildContext context) {
    final settlementAsync = ref.watch(settlementProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar ทรัพยากร
            settlementAsync.when(
              data: (s) => s != null
                  ? _ResourceBar(settlement: s)
                  : const SizedBox.shrink(),
              loading: () => const _ResourceBarSkeleton(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // Tab bar
            _TabBar(
              tabs: _tabs,
              currentIndex: _currentTab,
              onTap: (i) => setState(() => _currentTab = i),
            ),

            // Content
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  MapTab(onSwitchTab: switchTab),
                  const BuildingTab(),
                  const TroopTab(),
                  const CaravanTab(),
                  const NotificationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Resource bar ด้านบน
class _ResourceBar extends ConsumerWidget {
  final settlement;
  const _ResourceBar({required this.settlement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildings = ref.watch(buildingsProvider).valueOrNull ?? [];
    final rate = ProductionService.calculateHourlyRate(buildings);

    return Container(
      color: const Color(0xFF3C2810),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text(
            settlement.name,
            style: const TextStyle(
              color: Color(0xFFFAC775),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          _EnemyButton(),
          const Spacer(),
          _ResChip(
            icon: '🪵', value: settlement.wood,
            rate: rate['wood'] ?? 0,
          ),
          const SizedBox(width: 5),
          _ResChip(
            icon: '⚙️', value: settlement.iron,
            rate: rate['iron'] ?? 0,
          ),
          const SizedBox(width: 5),
          _ResChip(
            icon: '🌾', value: settlement.rice,
            rate: rate['rice'] ?? 0,
          ),
          const SizedBox(width: 5),
          _ResChip(
            icon: '🍶', value: settlement.liquor,
            rate: rate['liquor'] ?? 0,
          ),
        ],
      ),
    );
  }
}

class _EnemyButton extends ConsumerWidget {
  const _EnemyButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enemies = ref.watch(recentEnemiesProvider).valueOrNull ?? [];
    final hasEnemy = enemies.isNotEmpty;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const EnemySheet(),
      ),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: hasEnemy
                  ? const Color(0xFF993C1D).withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('⚔️',
              style: TextStyle(fontSize: 12)),
          ),
          if (hasEnemy)
            Positioned(
              right: 0, top: 0,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0997B),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResChip extends StatelessWidget {
  final String icon;
  final int value;
  final int rate;
  const _ResChip({
    required this.icon,
    required this.value,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$icon $value',
            style: const TextStyle(
              color: Color(0xFFFAC775),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (rate > 0)
            Text(
              '+$rate/ชม.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 8,
              ),
            ),
        ],
      ),
    );
  }
}

class _ResourceBarSkeleton extends StatelessWidget {
  const _ResourceBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: const Color(0xFF3C2810),
    );
  }
}

// Tab bar
class _TabBar extends StatelessWidget {
  final List<_TabItem> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TabBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color(0xFFF5EFE6),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF3C2810)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF854F0B)
                        : Colors.transparent,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    tabs[i].hasBadge
                        ? _NotifIcon(
                            icon: tabs[i].icon,
                            selected: selected,
                          )
                        : Icon(
                            tabs[i].icon,
                            size: 16,
                            color: selected
                                ? const Color(0xFFFAC775)
                                : const Color(0xFF888780),
                          ),
                    const SizedBox(height: 2),
                    Text(
                      tabs[i].label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: selected
                            ? const Color(0xFFFAC775)
                            : const Color(0xFF888780),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NotifIcon extends ConsumerWidget {
  final IconData icon;
  final bool selected;
  const _NotifIcon({required this.icon, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationsProvider).valueOrNull ?? [];
    final unread = notifs.where((n) => n['is_read'] == false).length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          icon,
          size: 16,
          color: selected
              ? const Color(0xFFFAC775)
              : const Color(0xFF888780),
        ),
        if (unread > 0)
          Positioned(
            right: -5,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF993C1D),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(
                  fontSize: 7,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final bool hasBadge;
  const _TabItem({required this.label, required this.icon, this.hasBadge = false});
}