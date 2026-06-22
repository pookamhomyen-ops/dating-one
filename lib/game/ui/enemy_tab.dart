import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../models/troop.dart';
import '../services/march_service.dart';

class EnemySheet extends ConsumerStatefulWidget {
  const EnemySheet({super.key});

  @override
  ConsumerState<EnemySheet> createState() => _EnemySheetState();
}

class _EnemySheetState extends ConsumerState<EnemySheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF1A0F05),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text('⚔️ ชุมนุมศัตรู',
            style: TextStyle(
              color: Color(0xFFFAC775),
              fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          // tabs
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF993C1D),
            labelColor: const Color(0xFFFAC775),
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: '24 ชั่วโมงล่าสุด'),
              Tab(text: 'ประวัติทั้งหมด'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _RecentEnemyList(),
                _EnemyHistoryList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ศัตรู 24 ชั่วโมง ────────────────────────────────────────────────────────
class _RecentEnemyList extends ConsumerWidget {
  const _RecentEnemyList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enemiesAsync = ref.watch(recentEnemiesProvider);

    return enemiesAsync.when(
      data: (enemies) => enemies.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🕊️', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 12),
                  Text('ยังไม่มีใครบุกใน 24 ชั่วโมงที่ผ่านมา',
                    style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: enemies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _EnemyCard(
                enemy: enemies[i],
                showRevengeButton: true,
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

// ─── ประวัติทั้งหมด ───────────────────────────────────────────────────────────
class _EnemyHistoryList extends ConsumerWidget {
  const _EnemyHistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(enemyHistoryProvider);

    return historyAsync.when(
      data: (enemies) => enemies.isEmpty
          ? const Center(
              child: Text('ยังไม่มีประวัติ',
                style: TextStyle(color: Colors.white54)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: enemies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _EnemyCard(
                enemy: enemies[i],
                showRevengeButton: false,
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

// ─── Card ศัตรู ───────────────────────────────────────────────────────────────
class _EnemyCard extends ConsumerWidget {
  final Map<String, dynamic> enemy;
  final bool showRevengeButton;

  const _EnemyCard({
    required this.enemy,
    required this.showRevengeButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = enemy['enemy_name'] as String? ?? '???';
    final attackedAt = DateTime.parse(enemy['attacked_at']);
    final isRevenged = enemy['is_revenged'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRevenged
              ? Colors.white12
              : const Color(0xFF993C1D).withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Text(isRevenged ? '✅' : '🔥',
            style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏯 $name',
                  style: const TextStyle(
                    color: Color(0xFFFAC775),
                    fontSize: 13, fontWeight: FontWeight.w600)),
                Text(_timeAgo(attackedAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ],
            ),
          ),
          if (showRevengeButton && !isRevenged)
            GestureDetector(
              onTap: () => _showRevengeSheet(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF993C1D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('⚔️ แค้น',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            )
          else if (isRevenged)
            Text('แก้แค้นแล้ว',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3), fontSize: 11)),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24)   return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }

  void _showRevengeSheet(BuildContext context, WidgetRef ref) {
    final troops = ref.read(troopsProvider).valueOrNull ?? [];
    final settlement = ref.read(settlementProvider).valueOrNull;
    if (settlement == null) return;

    final enemySettlementId = enemy['enemy_settlement_id'] as String?;
    if (enemySettlementId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0F05),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _RevengeSheet(
        enemyId: enemy['id'] as String,
        enemySettlementId: enemySettlementId,
        enemyName: enemy['enemy_name'] as String? ?? '???',
        mySettlement: settlement,
        troops: troops,
      ),
    );
  }
}

// ─── Sheet ส่งกองทัพแก้แค้น ──────────────────────────────────────────────────
class _RevengeSheet extends ConsumerStatefulWidget {
  final String enemyId;
  final String enemySettlementId;
  final String enemyName;
  final mySettlement;
  final List<Troop> troops;

  const _RevengeSheet({
    required this.enemyId,
    required this.enemySettlementId,
    required this.enemyName,
    required this.mySettlement,
    required this.troops,
  });

  @override
  ConsumerState<_RevengeSheet> createState() => _RevengeSheetState();
}

class _RevengeSheetState extends ConsumerState<_RevengeSheet> {
  final Map<String, int> _selected = {};
  bool _sending = false;

  int get _totalAttack {
    const power = {
      'swordsman': 10, 'archer': 12, 'spearman': 8,
      'cavalry': 18,  'elephant': 35,
    };
    int total = 0;
    _selected.forEach((type, count) {
      total += (power[type] ?? 10) * count;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚔️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('แก้แค้น',
                      style: TextStyle(
                        color: Color(0xFFFAC775),
                        fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('🏯 ${widget.enemyName}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  ],
                ),
              ),
              Text('กำลังรบ $_totalAttack',
                style: const TextStyle(
                  color: Color(0xFFF0997B), fontSize: 12)),
            ],
          ),
          const Divider(color: Color(0xFF5C3210), height: 20),

          ...widget.troops.where((t) => t.count > 0).map((t) {
            final sel = _selected[t.troopType] ?? 0;
            return Row(
              children: [
                Text('${t.emoji} ${t.displayName}',
                  style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
                const Spacer(),
                Text('มี ${t.count}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 11)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove, size: 16, color: Colors.white54),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: sel > 0
                      ? () => setState(() => _selected[t.troopType] = sel - 1)
                      : null,
                ),
                SizedBox(
                  width: 28,
                  child: Text('$sel',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16, color: Colors.white54),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: sel < t.count
                      ? () => setState(() => _selected[t.troopType] = sel + 1)
                      : null,
                ),
              ],
            );
          }),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF993C1D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _sending || _selected.values.every((v) => v == 0)
                  ? null
                  : _sendRevenge,
              child: _sending
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                  : const Text('⚔️ ส่งกองทัพแก้แค้น'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _sendRevenge() async {
    final troops = Map<String, int>.from(_selected)
      ..removeWhere((_, v) => v == 0);
    if (troops.isEmpty) return;

    setState(() => _sending = true);
    try {
      final service = MarchService(ref.read(supabaseProvider));
      await service.sendAttack(
        settlement: widget.mySettlement,
        targetNodeId: widget.enemySettlementId,
        troops: troops,
        travelMinutes: 15,
      );

      // mark is_revenged
      final gameClient = ref.read(gameSupabaseProvider);
      await gameClient
          .from('enemies')
          .update({'is_revenged': true})
          .eq('id', widget.enemyId);

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context); // ปิด EnemySheet ด้วย
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚔️ ส่งกองทัพแก้แค้นแล้ว!')));
        ref.invalidate(troopsProvider);
        ref.invalidate(recentEnemiesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งไม่ได้: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}