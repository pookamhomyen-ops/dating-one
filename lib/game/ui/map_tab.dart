import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../models/settlement.dart';
import '../models/troop.dart';
import '../services/game_service.dart';
import '../services/march_service.dart';
import '../ui/settlement_view.dart';

class MapTab extends ConsumerWidget {
  final void Function(int)? onSwitchTab;
  const MapTab({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync = ref.watch(settlementProvider);

    return settlementAsync.when(
      data: (settlement) => settlement != null
          ? _MapView(settlement: settlement, onSwitchTab: onSwitchTab)
          : const _CreateSettlementPrompt(),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
  }
}

// ─── แผนที่หลัก ───────────────────────────────────────────────────────────────
class _MapView extends ConsumerStatefulWidget {
  final Settlement settlement;
  final void Function(int)? onSwitchTab;
  const _MapView({required this.settlement, this.onSwitchTab});

  @override
  ConsumerState<_MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<_MapView> {
  static const double cellSize = 48.0;
  static const int mapSize = 100;

  late TransformationController _transformController;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnMySettlement());
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _centerOnMySettlement() {
    if (!mounted) return;
    final s = widget.settlement;
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height * 0.6;
    final tx = screenW / 2 - s.mapX * cellSize;
    final ty = screenH / 2 - s.mapY * cellSize;
    _transformController.value = Matrix4.identity()..translate(tx, ty);
  }

  void _onInteractionEnd(ScaleEndDetails _) {
    final m = _transformController.value;
    final tx = -m.entry(0, 3);
    final ty = -m.entry(1, 3);
    final cx = (tx / cellSize).clamp(0, mapSize).toDouble();
    final cy = (ty / cellSize).clamp(0, mapSize).toDouble();
    ref.read(mapViewportProvider.notifier).state = Offset(cx, cy);
  }

  @override
  Widget build(BuildContext context) {
    final troops  = ref.watch(troopsProvider).valueOrNull ?? [];
    final nodes   = ref.watch(mapNodesProvider).valueOrNull ?? [];
    final nearby  = ref.watch(nearbySettlementsProvider).valueOrNull ?? [];
    final season  = ref.watch(seasonProvider).valueOrNull ?? 'summer';

    return Column(
      children: [
        _HappinessBar(settlement: widget.settlement),
        Expanded(
          child: ClipRect(               // ← กัน InteractiveViewer ล้นกรอบ
            child: Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transformController,
                  boundaryMargin: const EdgeInsets.all(200),
                  minScale: 0.3,
                  maxScale: 2.5,
                  constrained: false,    // ← ให้ child ใหญ่กว่า viewport ได้
                  onInteractionEnd: _onInteractionEnd,
                  child: SizedBox(
                    width: mapSize * cellSize,
                    height: mapSize * cellSize,
                    child: Stack(
                      children: [
                        _MapBackground(
                          mapSize: mapSize,
                          cellSize: cellSize,
                          season: season,
                        ),
                        ..._buildNodes(nodes, troops),
                        ..._buildNearby(nearby, troops),
                        _MySettlement(settlement: widget.settlement),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'centerBtn',
                        backgroundColor: const Color(0xFF3C2810),
                        onPressed: _centerOnMySettlement,
                        child: const Text('🏯', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'settlementBtn',
                        backgroundColor: const Color(0xFF854F0B),
                        onPressed: () {
                          final container = ProviderScope.containerOf(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProviderScope(
                                parent: container,
                                child: SettlementView(
                                  onSwitchTab: widget.onSwitchTab,
                                ),
                              ),
                            ),
                          );
                        },
                        child: const Text('🏛️', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const _MarchHistory(),
        const SizedBox(height: 8),
      ],
    );
  }

  List<Widget> _buildNodes(List<Map<String, dynamic>> nodes, List<Troop> troops) {
    const emoji = {
      'bandit': '⚔️', 'forest': '🪵',
      'iron_mine': '⚙️', 'npc_settlement': '🏘️',
    };
    const colors = {
      'bandit': Color(0xFF993C1D),
      'forest': Color(0xFF185FA5),
      'iron_mine': Color(0xFF185FA5),
      'npc_settlement': Color(0xFF3B6D11),
    };
    return nodes.map((node) {
      final x = (node['map_x'] as int).toDouble();
      final y = (node['map_y'] as int).toDouble();
      final type = node['node_type'] as String;
      return Positioned(
        left: x * cellSize - cellSize / 2,
        top:  y * cellSize - cellSize / 2,
        child: GestureDetector(
          onTap: () => _showNodeAttackSheet(node, troops),
          child: _MapPin(
            emoji: emoji[type] ?? '❓',
            color: colors[type] ?? const Color(0xFF555555),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildNearby(List<Map<String, dynamic>> settlements, List<Troop> troops) {
    return settlements.map((s) {
      final x = (s['map_x'] as int).toDouble();
      final y = (s['map_y'] as int).toDouble();
      return Positioned(
        left: x * cellSize - cellSize / 2,
        top:  y * cellSize - cellSize / 2,
        child: GestureDetector(
          onTap: () => _showPlayerSheet(s, troops),
          child: _PlayerPin(
            name: s['display_name'] ?? '???',
            photoUrl: s['photo_url'],
          ),
        ),
      );
    }).toList();
  }

  void _showNodeAttackSheet(Map<String, dynamic> node, List<Troop> troops) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5EFE6),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AttackBottomSheet(
        node: node,
        settlement: widget.settlement,
        troops: troops,
      ),
    );
  }

  void _showPlayerSheet(Map<String, dynamic> playerSettlement, List<Troop> troops) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5EFE6),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PlayerAttackSheet(
        targetSettlement: playerSettlement,
        mySettlement: widget.settlement,
        troops: troops,
      ),
    );
  }
}

// ─── พื้นหลัง grid ────────────────────────────────────────────────────────────
class _MapBackground extends StatelessWidget {
  final int mapSize;
  final double cellSize;
  final String season;
  const _MapBackground({
    required this.mapSize,
    required this.cellSize,
    required this.season,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(mapSize * cellSize, mapSize * cellSize),
      painter: _GridPainter(
        mapSize: mapSize,
        cellSize: cellSize,
        season: season,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int mapSize;
  final double cellSize;
  final String season;
  const _GridPainter({
    required this.mapSize,
    required this.cellSize,
    required this.season,
  });

  Color get _mapBgColor {
    switch (season) {
      case 'summer': return const Color(0xFF8B7355); // สีดินแห้ง
      case 'rain':   return const Color(0xFF2D5A27); // สีเขียวเข้ม
      case 'winter': return const Color(0xFF6B8E9F); // สีฟ้าหมอก
      default:       return const Color(0xFF4A6741);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _mapBgColor,
    );
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= mapSize; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.season != season;
}

// ─── ชุมนุมของเรา ─────────────────────────────────────────────────────────────
class _MySettlement extends StatelessWidget {
  final Settlement settlement;
  const _MySettlement({required this.settlement});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: settlement.mapX * 48.0 - 28,
      top:  settlement.mapY * 48.0 - 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏯', style: TextStyle(fontSize: 28)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF3C2810).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              settlement.name,
              style: const TextStyle(
                color: Color(0xFFFAC775), fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── pin โหนด ─────────────────────────────────────────────────────────────────
class _MapPin extends StatelessWidget {
  final String emoji;
  final Color color;
  const _MapPin({required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

// ─── pin ผู้เล่นอื่น ──────────────────────────────────────────────────────────
class _PlayerPin extends StatelessWidget {
  final String name;
  final String? photoUrl;
  const _PlayerPin({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFAC775), width: 1.5),
            color: const Color(0xFF3C2810),
          ),
          child: ClipOval(
            child: photoUrl != null
                ? Image.network(photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Center(child: Text('🏯',
                            style: TextStyle(fontSize: 16))))
                : const Center(
                    child: Text('🏯', style: TextStyle(fontSize: 16))),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            name.length > 8 ? '${name.substring(0, 8)}…' : name,
            style: const TextStyle(color: Colors.white, fontSize: 8),
          ),
        ),
      ],
    );
  }
}

// ─── sheet โจมตีผู้เล่นอื่น ───────────────────────────────────────────────────
class _PlayerAttackSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> targetSettlement;
  final Settlement mySettlement;
  final List<Troop> troops;

  const _PlayerAttackSheet({
    required this.targetSettlement,
    required this.mySettlement,
    required this.troops,
  });

  @override
  ConsumerState<_PlayerAttackSheet> createState() =>
      _PlayerAttackSheetState();
}

class _PlayerAttackSheetState extends ConsumerState<_PlayerAttackSheet> {
  final Map<String, int> _selected = {};
  bool _sending = false;

  int get _travelMinutes {
    final dx = (widget.targetSettlement['map_x'] as int) - widget.mySettlement.mapX;
    final dy = (widget.targetSettlement['map_y'] as int) - widget.mySettlement.mapY;
    final dist = (dx * dx + dy * dy);
    return (dist / 10).clamp(5, 120).toInt();
  }

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
    final defense    = widget.targetSettlement['defense_power'] as int? ?? 50;
    final name       = widget.targetSettlement['name'] as String;
    final playerName = widget.targetSettlement['display_name'] as String? ?? '???';
    final photoUrl   = widget.targetSettlement['photo_url'] as String?;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header — รูปโปรไฟล์ + ชื่อ
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFFAC775), width: 1.5),
                ),
                child: ClipOval(
                  child: photoUrl != null
                      ? Image.network(photoUrl, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Center(child: Text('🏯')))
                      : const Center(child: Text('🏯',
                          style: TextStyle(fontSize: 20))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(playerName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('🏯 $name',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('🛡️ $defense',
                    style: const TextStyle(fontSize: 13)),
                  Text('⏱ $_travelMinutes นาที',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
          const Divider(height: 20),

          // เลือกทหาร
          ...widget.troops.where((t) => t.count > 0).map((t) {
            final sel = _selected[t.troopType] ?? 0;
            return Row(
              children: [
                Text('${t.emoji} ${t.displayName}',
                  style: const TextStyle(fontSize: 12)),
                const Spacer(),
                Text('มี ${t.count}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: sel > 0
                      ? () => setState(
                          () => _selected[t.troopType] = sel - 1)
                      : null,
                ),
                SizedBox(
                  width: 28,
                  child: Text('$sel',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13)),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: sel < t.count
                      ? () => setState(
                          () => _selected[t.troopType] = sel + 1)
                      : null,
                ),
              ],
            );
          }),

          const SizedBox(height: 12),
          Text(
            'กำลังรบ $_totalAttack vs 🛡️ $defense  •  '
            '${_totalAttack > defense ? "✅ น่าจะชนะ" : "⚠️ เสี่ยงแพ้"}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
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
              onPressed: _sending ||
                      _selected.values.every((v) => v == 0)
                  ? null
                  : _sendAttack,
              child: _sending
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('⚔️ บุกชุมนุม'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _sendAttack() async {
    final troops = Map<String, int>.from(_selected)
      ..removeWhere((_, v) => v == 0);
    if (troops.isEmpty) return;

    setState(() => _sending = true);
    try {
      final service = MarchService(ref.read(supabaseProvider));
      await service.sendAttack(
        settlement: widget.mySettlement,
        targetNodeId: widget.targetSettlement['id'] as String,
        troops: troops,
        travelMinutes: _travelMinutes,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚔️ ส่งกองทัพบุกแล้ว!')),
        );
        ref.invalidate(troopsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งไม่ได้: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

// ─── Happiness Bar ────────────────────────────────────────────────────────────
class _HappinessBar extends ConsumerWidget {
  final Settlement settlement;
  const _HappinessBar({required this.settlement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defense = ref.watch(settlementDefenseProvider);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('ความพึงพอใจ',
            style: TextStyle(color: Color(0xFFF0997B), fontSize: 11)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: settlement.happiness / 100,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(
                  settlement.happiness >= 70
                      ? const Color(0xFF5DCAA5)
                      : settlement.happiness >= 40
                          ? const Color(0xFFFAC775)
                          : const Color(0xFFF0997B),
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(settlement.happinessEmoji,
            style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('${settlement.happiness}%',
            style: const TextStyle(
              color: Color(0xFFFAC775),
              fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Text('🛡️$defense',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── March History ────────────────────────────────────────────────────────────
class _MarchHistory extends ConsumerWidget {
  const _MarchHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(marchHistoryProvider);
    return historyAsync.when(
      data: (marches) {
        if (marches.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
              child: Text('ประวัติการรบ',
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ),
            ...marches.map((m) => _MarchHistoryCard(march: m)),
            const SizedBox(height: 4),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _MarchHistoryCard extends StatelessWidget {
  final dynamic march;
  const _MarchHistoryCard({required this.march});

  @override
  Widget build(BuildContext context) {
    final isVictory = march.loot.isNotEmpty;
    final lootText = (march.loot as Map<String, int>).entries
        .map((e) => '${_icon(e.key)}${e.value}').join(' ');
    final troopsText = (march.troopsSent as Map<String, int>).entries
        .map((e) => '${e.value}${_troopEmoji(e.key)}').join(' ');

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isVictory
                ? const Color(0xFF5DCAA5)
                : const Color(0xFFF0997B),
            width: 3,
          ),
          top:    BorderSide(color: Colors.black.withValues(alpha: 0.06), width: 0.5),
          right:  BorderSide(color: Colors.black.withValues(alpha: 0.06), width: 0.5),
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(isVictory ? '🏆' : '💀',
            style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isVictory ? 'ชนะ — ได้ $lootText' : 'แพ้ — ไม่ได้ของ',
                  style: const TextStyle(fontSize: 12)),
                Text('ส่ง $troopsText • ${_timeAgo(march.arriveAt)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _icon(String res) {
    const m = {'wood':'🪵','iron':'⚙️','rice':'🌾','liquor':'🍶'};
    return m[res] ?? res;
  }

  String _troopEmoji(String type) {
    const m = {'swordsman':'🗡️','archer':'🏹','spearman':'🪖',
               'cavalry':'🐴','elephant':'🐘'};
    return m[type] ?? '⚔️';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24)   return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }
}

// ─── Attack Bottom Sheet (โหนด) ───────────────────────────────────────────────
class _AttackBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> node;
  final Settlement settlement;
  final List<Troop> troops;

  const _AttackBottomSheet({
    required this.node,
    required this.settlement,
    required this.troops,
  });

  @override
  ConsumerState<_AttackBottomSheet> createState() =>
      _AttackBottomSheetState();
}

class _AttackBottomSheetState extends ConsumerState<_AttackBottomSheet> {
  final Map<String, int> _selected = {};
  bool _sending = false;

  static const _nodeLabel = {
    'bandit': 'โหนดโจร', 'forest': 'ป่าไม้',
    'iron_mine': 'แร่เหล็ก', 'npc_settlement': 'ชุมนุม NPC',
  };

  int get _travelMinutes {
    final dx = (widget.node['map_x'] as int) - widget.settlement.mapX;
    final dy = (widget.node['map_y'] as int) - widget.settlement.mapY;
    final dist = (dx * dx + dy * dy);
    return (dist / 10).clamp(5, 60).toInt();
  }

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
    final type    = widget.node['node_type'] as String;
    final defense = widget.node['defense_power'] as int;
    final loot    = widget.node['loot_pool'] as Map<String, dynamic>;
    final label   = _nodeLabel[type] ?? type;

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
              Text(label, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('🛡️ $defense',
                style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'สมบัติ: ${loot.entries.map((e) => '${e.key} ×${e.value}').join('  ')}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          Text(
            'เวลาเดินทาง $_travelMinutes นาที  •  กำลังรบ $_totalAttack / $defense',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const Divider(height: 20),
          ...widget.troops.where((t) => t.count > 0).map((t) {
            final sel = _selected[t.troopType] ?? 0;
            return Row(
              children: [
                Text('${t.emoji} ${t.displayName}',
                  style: const TextStyle(fontSize: 12)),
                const Spacer(),
                Text('มี ${t.count}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: sel > 0
                      ? () => setState(
                          () => _selected[t.troopType] = sel - 1)
                      : null,
                ),
                SizedBox(
                  width: 28,
                  child: Text('$sel',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13)),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: sel < t.count
                      ? () => setState(
                          () => _selected[t.troopType] = sel + 1)
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
                backgroundColor: const Color(0xFF3C2810),
                foregroundColor: const Color(0xFFFAC775),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _sending ||
                      _selected.values.every((v) => v == 0)
                  ? null
                  : _sendAttack,
              child: _sending
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('⚔️ ส่งกองทัพ'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _sendAttack() async {
    final troops = Map<String, int>.from(_selected)
      ..removeWhere((_, v) => v == 0);
    if (troops.isEmpty) return;

    setState(() => _sending = true);
    try {
      final service = MarchService(ref.read(supabaseProvider));
      await service.sendAttack(
        settlement: widget.settlement,
        targetNodeId: widget.node['id'] as String,
        troops: troops,
        travelMinutes: _travelMinutes,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚔️ ส่งกองทัพแล้ว!')),
        );
        ref.invalidate(troopsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งไม่ได้: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

// ─── Create Settlement ────────────────────────────────────────────────────────
final settlementCreationLoadingProvider =
    AutoDisposeStateProvider<bool>((ref) => false);

class _CreateSettlementPrompt extends ConsumerStatefulWidget {
  const _CreateSettlementPrompt();

  @override
  ConsumerState<_CreateSettlementPrompt> createState() =>
      _CreateSettlementPromptState();
}

class _CreateSettlementPromptState
    extends ConsumerState<_CreateSettlementPrompt> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    _nameController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5EFE6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏯 ตั้งชุมนุมใหม่',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('ตำแหน่งจะถูกสุ่มให้อัตโนมัติ',
              style: TextStyle(fontSize: 12, color: Color(0xFF888780))),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'ชื่อชุมนุม',
                hintText: 'เช่น อยุทธยาเหนือ',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF854F0B)),
                ),
              ),
              maxLength: 20,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C2810),
                  foregroundColor: const Color(0xFFFAC775),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  _createSettlement(name);
                },
                child: const Text('สร้างชุมนุม'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _createSettlement(String name) async {
    ref.read(settlementCreationLoadingProvider.notifier).state = true;
    try {
      final service = GameService(ref.read(supabaseProvider));
      final random = DateTime.now().millisecondsSinceEpoch;
      final mapX = (random % 50) + 1;
      final mapY = (random ~/ 100 % 50) + 1;
      await service.createSettlement(name: name, mapX: mapX, mapY: mapY);
      ref.invalidate(settlementProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('สร้างไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) {
        ref.read(settlementCreationLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(settlementCreationLoadingProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏯', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('ยังไม่มีชุมนุม',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('สร้างชุมนุมแรกของคุณเพื่อเริ่มเกม',
            style: TextStyle(fontSize: 13, color: Color(0xFF888780))),
          const SizedBox(height: 20),
          isLoading
              ? const CircularProgressIndicator(color: Color(0xFF3C2810))
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C2810),
                    foregroundColor: const Color(0xFFFAC775),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _showCreateDialog,
                  child: const Text('⚔️ สร้างชุมนุม'),
                ),
        ],
      ),
    );
  }
}