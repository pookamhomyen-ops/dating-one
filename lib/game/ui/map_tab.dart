import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../models/settlement.dart';

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
                _MapNode(
                  top: 20, left: 20,
                  emoji: '⚔️',
                  label: 'โหนดโจร',
                  color: const Color(0xFF993C1D),
                  onTap: () => _showNodeDialog(context, 'โหนดโจร', 15),
                ),
                _MapNode(
                  top: 20, right: 24,
                  emoji: '🪵',
                  label: 'ป่าไม้',
                  color: const Color(0xFF185FA5),
                  onTap: () => _showNodeDialog(context, 'ป่าไม้', 10),
                ),
                _MapNode(
                  bottom: 24, left: 22,
                  emoji: '⚙️',
                  label: 'แร่เหล็ก',
                  color: const Color(0xFF185FA5),
                  onTap: () => _showNodeDialog(context, 'แร่เหล็ก', 12),
                ),
                _MapNode(
                  bottom: 20, right: 18,
                  emoji: '🏘️',
                  label: 'ชุมนุม NPC',
                  color: const Color(0xFF3B6D11),
                  onTap: () => _showNodeDialog(context, 'ชุมนุม NPC', 20),
                ),

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

  void _showNodeDialog(BuildContext context, String name, int travelMinutes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5EFE6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AttackBottomSheet(
        nodeName: name,
        travelMinutes: travelMinutes,
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

class _AttackBottomSheet extends StatelessWidget {
  final String nodeName;
  final int travelMinutes;

  const _AttackBottomSheet({
    required this.nodeName,
    required this.travelMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nodeName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'เวลาเดินทาง $travelMinutes นาที',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3C2810),
                foregroundColor: const Color(0xFFFAC775),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('ส่งกองทัพ'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CreateSettlementPrompt extends StatelessWidget {
  const _CreateSettlementPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏯', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'ยังไม่มีชุมนุม',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C2810),
              foregroundColor: const Color(0xFFFAC775),
            ),
            onPressed: () {},
            child: const Text('สร้างชุมนุม'),
          ),
        ],
      ),
    );
  }
}