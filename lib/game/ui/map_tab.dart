import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../models/settlement.dart';
import '../models/troop.dart';
import '../services/game_service.dart';
import '../services/march_service.dart';

class MapTab extends ConsumerWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync = ref.watch(settlementProvider);

    return settlementAsync.when(
      data: (settlement) => settlement != null
          ? _MapView(settlement: settlement)
          : const _CreateSettlementPrompt(),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
  }
}

class _MapView extends StatelessWidget {
  final Settlement settlement;
  const _MapView({required this.settlement});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Happiness bar
        _HappinessBar(settlement: settlement),

        // แผนที่
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A6741),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Grid
                const _MapGrid(),

                // โหนดต่างๆ
                _MapNodes(settlement: settlement),

                // ชุมนุมของผู้เล่น (กลาง)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏯', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          settlement.name,
                          style: const TextStyle(
                            color: Color(0xFFFAC775),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // population badge
                Positioned(
                  bottom: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ประชาชน ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '${settlement.population} คน',
                          style: const TextStyle(
                            color: Color(0xFFFAC775),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'กดที่โหนดเพื่อส่งกองทัพ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  void _showNodeDialog(
    BuildContext context,
    Map<String, dynamic> node,
    List<Troop> troops,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5EFE6),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AttackBottomSheet(
        node: node,
        settlement: settlement,
        troops: troops,
      ),
    );
  }
}

class _MapNodes extends ConsumerWidget {
  final Settlement settlement;
  const _MapNodes({required this.settlement});

  static const _nodeEmoji = {
    'bandit':         '⚔️',
    'forest':         '🪵',
    'iron_mine':      '⚙️',
    'npc_settlement': '🏘️',
  };
  static const _nodeLabel = {
    'bandit':         'โหนดโจร',
    'forest':         'ป่าไม้',
    'iron_mine':      'แร่เหล็ก',
    'npc_settlement': 'ชุมนุม NPC',
  };
  static const _nodeColor = {
    'bandit':         Color(0xFF993C1D),
    'forest':         Color(0xFF185FA5),
    'iron_mine':      Color(0xFF185FA5),
    'npc_settlement': Color(0xFF3B6D11),
  };

  // ตำแหน่ง 4 มุม
  static const _positions = [
    {'top': 20.0,  'left': 20.0},
    {'top': 20.0,  'right': 24.0},
    {'bottom': 24.0, 'left': 22.0},
    {'bottom': 20.0, 'right': 18.0},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodesAsync = ref.watch(mapNodesProvider);
    final troopsAsync = ref.watch(troopsProvider);

    return nodesAsync.when(
      data: (nodes) => troopsAsync.when(
        data: (troops) => Stack(
          children: List.generate(nodes.length > 4 ? 4 : nodes.length, (i) {
            final node = nodes[i];
            final pos = _positions[i];
            final type = node['node_type'] as String;
            return Positioned(
              top: pos['top'],
              left: pos['left'],
              right: pos['right'],
              bottom: pos['bottom'],
              child: _MapNode(
                emoji: _nodeEmoji[type] ?? '❓',
                label: _nodeLabel[type] ?? type,
                color: _nodeColor[type] ?? const Color(0xFF555555),
                onTap: () => _showAttackSheet(context, node, troops),
              ),
            );
          }),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showAttackSheet(
    BuildContext context,
    Map<String, dynamic> node,
    List<Troop> troops,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5EFE6),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AttackBottomSheet(
        node: node,
        settlement: settlement,
        troops: troops,
      ),
    );
  }
}

class _HappinessBar extends StatelessWidget {
  final Settlement settlement;
  const _HappinessBar({required this.settlement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text(
            'ความพึงพอใจ',
            style: TextStyle(color: Color(0xFFF0997B), fontSize: 11),
          ),
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
          Text(
            settlement.happinessEmoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            '${settlement.happiness}%',
            style: const TextStyle(
              color: Color(0xFFFAC775),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGrid extends StatelessWidget {
  const _MapGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _GridPainter(),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.5;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _MapNode extends StatelessWidget {
  final double? top, left, right, bottom;
  final String emoji, label;
  final Color color;
  final VoidCallback onTap;

  const _MapNode({
    this.top, this.left, this.right, this.bottom,
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, left: left, right: right, bottom: bottom,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white30,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  ConsumerState<_AttackBottomSheet> createState() => _AttackBottomSheetState();
}

class _AttackBottomSheetState extends ConsumerState<_AttackBottomSheet> {
  final Map<String, int> _selected = {};
  bool _sending = false;

  static const _nodeLabel = {
    'bandit':         'โหนดโจร',
    'forest':         'ป่าไม้',
    'iron_mine':      'แร่เหล็ก',
    'npc_settlement': 'ชุมนุม NPC',
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
    final type = widget.node['node_type'] as String;
    final defense = widget.node['defense_power'] as int;
    final loot = widget.node['loot_pool'] as Map<String, dynamic>;
    final label = _nodeLabel[type] ?? type;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ
          Row(
            children: [
              Text(label,
                style: const TextStyle(
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
                    ? () => setState(() => _selected[t.troopType] = sel - 1)
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
                backgroundColor: const Color(0xFF3C2810),
                foregroundColor: const Color(0xFFFAC775),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _sending || _selected.values.every((v) => v == 0)
                ? null
                : _sendAttack,
              child: _sending
                ? const SizedBox(
                    width: 18, height: 18,
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

final settlementCreationLoadingProvider = AutoDisposeStateProvider<bool>((ref) => false);

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
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏯 ตั้งชุมนุมใหม่',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ตำแหน่งจะถูกสุ่มให้อัตโนมัติ',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF888780),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'ชื่อชุมนุม',
                hintText: 'เช่น อยุทธยาเหนือ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF854F0B),
                  ),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
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
      // ส่ง Client ตัวหลักเข้าไป เพื่อให้ GameService ดึงสิทธิ์ auth.currentUser ได้แบบเสถียรที่สุด
final service = GameService(ref.read(supabaseProvider));

      // สุ่มตำแหน่งบนแผนที่
      final random = DateTime.now().millisecondsSinceEpoch;
      final mapX = (random % 50) + 1;
      final mapY = (random ~/ 100 % 50) + 1;

      await service.createSettlement(
        name: name,
        mapX: mapX,
        mapY: mapY,
      );

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
          const Text(
            'ยังไม่มีชุมนุม',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'สร้างชุมนุมแรกของคุณเพื่อเริ่มเกม',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF888780),
            ),
          ),
          const SizedBox(height: 20),
          isLoading
              ? const CircularProgressIndicator(
                  color: Color(0xFF3C2810),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C2810),
                    foregroundColor: const Color(0xFFFAC775),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _showCreateDialog,
                  child: const Text('⚔️ สร้างชุมนุม'),
                ),
        ],
      ),
    );
  }
}