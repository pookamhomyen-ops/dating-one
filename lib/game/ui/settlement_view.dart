import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../models/building.dart';
import '../models/settlement.dart';
import '../services/building_service.dart';

class SettlementView extends ConsumerWidget {
  final void Function(int)? onSwitchTab;
  const SettlementView({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync = ref.watch(settlementProvider);
    final buildingsAsync  = ref.watch(buildingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF2A1A08),
      body: settlementAsync.when(
        data: (settlement) => buildingsAsync.when(
          data: (buildings) => settlement != null
              ? _SettlementScene(
                  settlement: settlement,
                  buildings: buildings,
                  onSwitchTab: onSwitchTab,
                )
              : const SizedBox.shrink(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

// ─── Scene หลัก ───────────────────────────────────────────────────────────────
class _SettlementScene extends StatelessWidget {
  final Settlement settlement;
  final List<Building> buildings;
  final void Function(int)? onSwitchTab;
  const _SettlementScene({
    required this.settlement,
    required this.buildings,
    this.onSwitchTab,
  });

  // ตำแหน่ง % ของแต่ละ building_type บนหน้าจอ
  static const _positions = <String, Offset>{
    'town_hall':      Offset(0.42, 0.32), // กลางบน
    'barracks':       Offset(0.62, 0.52), // ขวากลาง
    'sawmill':        Offset(0.25, 0.38), // ซ้ายบน
    'smelter':        Offset(0.68, 0.36), // ขวาบน
    'rice_farm':      Offset(0.28, 0.62), // ซ้ายล่าง
    'distillery':     Offset(0.58, 0.68), // ขวาล่าง
    'house':          Offset(0.42, 0.55), // กลาง
    'tavern':         Offset(0.50, 0.44), // กลางบน
    'shrine':         Offset(0.72, 0.60), // ขวาล่าง
    'elephant_camp':  Offset(0.22, 0.52), // ซ้ายกลาง
    'smithy':         Offset(0.65, 0.44), // ขวากลางบน
    'wall':           Offset(0.35, 0.46), // กลางซ้าย
    'watchtower':     Offset(0.55, 0.38), // กลางขวาบน
  };

  static const _assetPath = 'assets/games/buildings';

  static const _imageMap = <String, String>{
    'town_hall':   'town_hall.webp',
    'barracks':    'barracks.webp',
    'sawmill':     'sawmill.webp',
    'smelter':     'smelter.webp',
    'rice_farm':   'rice_farm.webp',
    'shrine':      'shrine.webp',
  };

  // fallback emoji สำหรับอาคารที่ยังไม่มีรูป
  static const _emoji = <String, String>{
    'distillery':    '🍶',
    'house':         '🏠',
    'tavern':        '🍺',
    'elephant_camp': '🐘',
    'smithy':        '🔨',
    'wall':          '🧱',
    'watchtower':    '🗼',
  };

  String _getImagePath(Building b) {
    if (b.buildingType == 'house') {
      final variant = (b.houseVariant ?? 1).clamp(1, 4);
      return '$_assetPath/house_$variant.webp';
    }
    final img = _imageMap[b.buildingType];
    if (img != null) return '$_assetPath/$img';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // พื้นหลัง gradient อยุทธยา
        _AyutthayaBackground(),

        // top bar
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: _TopBar(settlement: settlement),
          ),
        ),

        // อาคารต่างๆ
        ...buildings.map((b) {
          final pos = _positions[b.buildingType];
          if (pos == null) return const SizedBox.shrink();
          final imagePath = _getImagePath(b);
          return _BuildingIcon(
            building: b,
            imagePath: imagePath.isNotEmpty ? imagePath : null,
            emoji: _emoji[b.buildingType] ?? '🏛️',
            position: pos,
            settlement: settlement,
            onSwitchTab: onSwitchTab,
          );
        }),

        // ปุ่มกลับ
        Positioned(
          top: 0, left: 0,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                color: Color(0xFFFAC775), size: 20),
              onPressed: () {
                  Navigator.pop(context);  // ปิด popup
                  onSwitchTab?.call(_getTabIndex());
                },
            ),
          ),
        ),
      ],
    );
  }
}

// ─── พื้นหลัง ─────────────────────────────────────────────────────────────────
class _AyutthayaBackground extends ConsumerWidget {
  const _AyutthayaBackground();

  String _getBgPath(String season) {
    switch (season) {
      case 'summer': return 'assets/games/bg/bg_summer.png';
      case 'rain':   return 'assets/games/bg/bg_rain.png';
      case 'winter': return 'assets/games/bg/bg_winter.png';
      default:       return 'assets/games/bg/bg.png';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonAsync = ref.watch(seasonProvider);
    final season = seasonAsync.valueOrNull ?? 'summer';
    final bgPath = _getBgPath(season);

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            bgPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/games/bg/bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A0F05), Color(0xFF3D1F08), Color(0xFF5C3210), Color(0xFF4A6741)],
                  ),
                ),
              ),
            ),
          ),
        ),
        // กำแพงเมือง (ซ่อนไว้ก่อน)
        // Positioned.fill(child: CustomPaint(painter: _WallPainter())),
      ],
    );
  }
}

class _WallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wallRect = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.18,
      size.width * 0.84,
      size.height * 0.64,
    );

    final path = Path()
      ..moveTo(wallRect.left, wallRect.top)
      ..lineTo(wallRect.right, wallRect.top)
      ..lineTo(wallRect.right, wallRect.bottom)
      ..lineTo(wallRect.left, wallRect.bottom)
      ..close();

    final points = <Offset>[
      Offset(wallRect.left + wallRect.width * 0.15, wallRect.top),
      Offset(wallRect.left + wallRect.width * 0.25, wallRect.top),
      Offset(wallRect.left + wallRect.width * 0.45, wallRect.top),
      Offset(wallRect.left + wallRect.width * 0.65, wallRect.top),
      Offset(wallRect.left + wallRect.width * 0.85, wallRect.top),
      Offset(wallRect.left + wallRect.width * 0.15, wallRect.bottom),
      Offset(wallRect.left + wallRect.width * 0.85, wallRect.bottom),
    ];

    // เงา
    canvas.drawPath(path, Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // กำแพงไม้ชั้นนอก
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF6B3A10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12);

    // ลายไม้
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF8B5E2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5);

    // ไฮไลท์
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFFD4A057).withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // เสาไม้ตามจุด
    for (final p in points) {
      canvas.drawCircle(p, 7, Paint()
        ..color = const Color(0xFF4A2508)
        ..style = PaintingStyle.fill);
      canvas.drawCircle(p, 7, Paint()
        ..color = const Color(0xFFD4A057).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
      canvas.drawCircle(Offset(p.dx, p.dy - 3), 4, Paint()
        ..color = const Color(0xFF8B5E2A)
        ..style = PaintingStyle.fill);
    }

    // ประตูบน
    _drawWoodGate(canvas, points[0], true);
    // ประตูล่าง
    _drawWoodGate(canvas, points[5], false);
  }

  void _drawWoodPosts(Canvas canvas, double cx, double cy,
      double rx, double ry) {
    final postPaint = Paint()
      ..color = const Color(0xFF4A2508)
      ..style = PaintingStyle.fill;
    final postBorder = Paint()
      ..color = const Color(0xFFD4A057).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const count = 14;
    for (int i = 0; i < count; i++) {
      // หลีกเลี่ยงตำแหน่งประตู (บนและล่าง)
      if (i == 0 || i == count ~/ 2) continue;
      final angle = (i / count) * 2 * math.pi;
      final x = cx + rx * 0.98 * math.cos(angle);
      final y = cy + ry * 0.98 * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 7, postPaint);
      canvas.drawCircle(Offset(x, y), 7, postBorder);
      // หัวเสา
      final capPaint = Paint()
        ..color = const Color(0xFF8B5E2A)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y - 3), 4, capPaint);
    }
  }

  void _drawWoodGate(Canvas canvas, Offset center, bool isTop) {
    final basePaint = Paint()
      ..color = const Color(0xFF4A2508)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFFD4A057)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final gateRect = Rect.fromCenter(
      center: center, width: 44, height: 24);
    canvas.drawRect(gateRect, basePaint);
    canvas.drawRect(gateRect, borderPaint);

    final archPaint = Paint()
      ..color = const Color(0xFF2A1A08)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx,
            isTop ? center.dy + 4 : center.dy - 4),
        width: 18, height: 16),
      archPaint,
    );

    final roofPaint = Paint()
      ..color = const Color(0xFF8B1A1A).withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final roofPath = Path()
      ..moveTo(center.dx, isTop ? center.dy - 20 : center.dy + 20)
      ..lineTo(center.dx - 24, isTop ? center.dy - 8 : center.dy + 8)
      ..lineTo(center.dx + 24, isTop ? center.dy - 8 : center.dy + 8)
      ..close();
    canvas.drawPath(roofPath, roofPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends ConsumerWidget {
  final Settlement settlement;
  const _TopBar({required this.settlement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildings = ref.watch(buildingsProvider).valueOrNull ?? [];
    final thLevel   = ref.watch(townHallLevelProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(44, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF8B6914).withOpacity(0.5), width: 0.5),
      ),
      child: Row(
        children: [
          Text(settlement.name,
            style: const TextStyle(
              color: Color(0xFFFAC775),
              fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF854F0B).withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('🏛️ Lv.$thLevel',
              style: const TextStyle(color: Color(0xFFFAC775), fontSize: 10)),
          ),
          const Spacer(),
          _ResChip(icon: '🪵', value: settlement.wood),
          const SizedBox(width: 4),
          _ResChip(icon: '⚙️', value: settlement.iron),
          const SizedBox(width: 4),
          _ResChip(icon: '🌾', value: settlement.rice),
          const SizedBox(width: 4),
          _ResChip(icon: '🍶', value: settlement.liquor),
        ],
      ),
    );
  }
}

class _ResChip extends StatelessWidget {
  final String icon;
  final int value;
  const _ResChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text('$icon$value',
      style: const TextStyle(color: Color(0xFFFAC775), fontSize: 10));
  }
}

// ─── Building Icon บนแผนที่ ───────────────────────────────────────────────────
class _BuildingIcon extends StatelessWidget {
  final Building building;
  final String? imagePath;
  final String emoji;
  final Offset position;
  final Settlement settlement;
  final void Function(int)? onSwitchTab;

  const _BuildingIcon({
    required this.building,
    this.imagePath,
    required this.emoji,
    required this.position,
    required this.settlement,
    this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final left = position.dx * size.width - 28;
    final top  = position.dy * size.height - 40;

    return Positioned(
      left: left, top: top,
          child: GestureDetector(
            onTap: () => _showBuildingPopup(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // อาคาร
                Stack(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        imagePath != null
                            ? Image.asset(
                                imagePath!,
                                width: 60, height: 60,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Text(emoji,
                                  style: const TextStyle(fontSize: 36)),
                              )
                            : Text(emoji,
                                style: const TextStyle(fontSize: 36)),
                        if (building.isUpgrading)
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0997B).withOpacity(0.85),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                building.upgradeTimeRemaining != null
                                    ? _fmt(building.upgradeTimeRemaining!)
                                    : '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 8, color: Colors.white,
                                  fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // countdown badge
                    if (building.isUpgrading &&
                        building.upgradeTimeRemaining != null)
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0997B).withOpacity(0.9),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(10)),
                          ),
                          child: Text(
                            _fmt(building.upgradeTimeRemaining!),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 8, color: Colors.white,
                              fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                // ชื่อ + level
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${building.displayName} ${building.level}',
                    style: const TextStyle(
                      color: Color(0xFFFAC775), fontSize: 8),
                  ),
                ),
              ],
            ),
          ),
        );
  }

  String _fmt(Duration d) {
    if (d.inHours > 0)   return '${d.inHours}ชม.${d.inMinutes.remainder(60)}น.';
    if (d.inMinutes > 0) return '${d.inMinutes}น.${d.inSeconds.remainder(60)}ว.';
    return '${d.inSeconds}ว.';
  }

  void _showBuildingPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A1A08),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _BuildingPopup(
        building: building,
        settlement: settlement,
        onSwitchTab: onSwitchTab,
      ),
    );
  }
}

// ─── Popup อาคาร ──────────────────────────────────────────────────────────────
class _BuildingPopup extends ConsumerWidget {
  final Building building;
  final Settlement settlement;
  final void Function(int)? onSwitchTab;
  const _BuildingPopup({
    required this.building,
    required this.settlement,
    this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cost = building.upgradeCost;
    final canAfford = settlement.wood >= (cost['wood'] ?? 0) &&
        settlement.iron >= (cost['iron'] ?? 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ
          Row(
            children: [
              Text(building.displayName,
                style: const TextStyle(
                  color: Color(0xFFFAC775),
                  fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF854F0B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Lv.${building.level}',
                  style: const TextStyle(
                    color: Color(0xFFFAEEDA), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // production info
          if (building.productionPerTick.isNotEmpty) ...[
            _InfoRow(
              icon: '📦',
              text: building.productionPerTick.entries
                  .map((e) => '${_resIcon(e.key)} +${e.value}/5นาที')
                  .join('  '),
            ),
            const SizedBox(height: 4),
          ],

          if (building.defenseBonus > 0)
            _InfoRow(icon: '🛡️', text: '+${building.defenseBonus} defense'),

          if (building.populationBonus > 0)
            _InfoRow(icon: '👥', text: '+${building.populationBonus} ประชาชน'),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF5C3210)),
          const SizedBox(height: 12),

          // upgrade status
          if (building.isUpgrading && building.upgradeTimeRemaining != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5C3210),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('⏱', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'กำลังอัปเกรด Lv.${building.level} → ${building.level+1}  '
                    '(${_fmt(building.upgradeTimeRemaining!)})',
                    style: const TextStyle(
                      color: Color(0xFFF0997B), fontSize: 12)),
                ],
              ),
            )
          else if (building.level < 5) ...[
            Text('อัปเกรด → Lv.${building.level + 1}',
              style: const TextStyle(
                color: Color(0xFFFAC775), fontSize: 13,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _CostBadge(
                  icon: '🪵', need: cost['wood'] ?? 0,
                  have: settlement.wood),
                const SizedBox(width: 8),
                _CostBadge(
                  icon: '⚙️', need: cost['iron'] ?? 0,
                  have: settlement.iron),
                const SizedBox(width: 8),
                Text('⏱ ${_fmtSec(building.upgradeSeconds)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford
                      ? const Color(0xFF854F0B)
                      : Colors.grey[800],
                  foregroundColor: canAfford
                      ? const Color(0xFFFAEEDA)
                      : Colors.grey[500],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: canAfford
                    ? () => _upgrade(context, ref)
                    : null,
                child: Text(canAfford
                    ? '⚒️ อัปเกรด'
                    : 'ทรัพยากรไม่พอ'),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF5DCAA5).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Text('✅', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 8),
                  Text('อาคารถึงระดับสูงสุดแล้ว',
                    style: TextStyle(
                      color: Color(0xFF5DCAA5), fontSize: 12)),
                ],
              ),
            ),

          // action button (เข้าจัดการ)
          if (_hasAction) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFF8B6914), width: 0.5),
                  foregroundColor: const Color(0xFFFAC775),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToAction(context);
                },
                child: Text(_actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasAction => const [
    'barracks', 'elephant_camp', 'sawmill', 'smelter',
    'rice_farm', 'distillery', 'town_hall',
  ].contains(building.buildingType);

  String get _actionLabel {
    switch (building.buildingType) {
      case 'barracks':
      case 'elephant_camp': return '⚔️ เข้าจัดการทหาร';
      case 'sawmill':
      case 'smelter':
      case 'rice_farm':
      case 'distillery':    return '📦 ดูการผลิต';
      case 'town_hall':     return '🏛️ จัดการชุมนุม';
      default:              return '➡️ เข้าจัดการ';
    }
  }

  void _navigateToAction(BuildContext context) {
    // navigate ไปยัง tab ที่เกี่ยวข้องใน GameScreen
    // ใช้ pop กลับไปก่อน แล้ว GameScreen จะ handle tab ได้
  }

  Future<void> _upgrade(BuildContext context, WidgetRef ref) async {
    final service = BuildingService(ref.read(gameSupabaseProvider));
    try {
      await service.startUpgrade(
        building: building, settlement: settlement);
      ref.invalidate(buildingsProvider);
      ref.invalidate(settlementProvider);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')));
      }
    }
  }

  String _resIcon(String res) {
    const m = {'wood':'🪵','iron':'⚙️','rice':'🌾','liquor':'🍶'};
    return m[res] ?? res;
  }

  String _fmt(Duration d) {
    if (d.inHours > 0)   return '${d.inHours}ชม.${d.inMinutes.remainder(60)}น.';
    if (d.inMinutes > 0) return '${d.inMinutes}น.${d.inSeconds.remainder(60)}ว.';
    return '${d.inSeconds}ว.';
  }

  String _fmtSec(int s) {
    final d = Duration(seconds: s);
    if (d.inHours > 0)   return '${d.inHours}ชม.${d.inMinutes.remainder(60)}น.';
    if (d.inMinutes > 0) return '${d.inMinutes}น.';
    return '${d.inSeconds}ว.';
  }
}

class _InfoRow extends StatelessWidget {
  final String icon, text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text(text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }
}

class _CostBadge extends StatelessWidget {
  final String icon;
  final int need, have;
  const _CostBadge({required this.icon, required this.need, required this.have});

  @override
  Widget build(BuildContext context) {
    final enough = have >= need;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enough
            ? const Color(0xFF0F6E56).withOpacity(0.3)
            : const Color(0xFFA32D2D).withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: enough
              ? const Color(0xFF5DCAA5).withOpacity(0.4)
              : const Color(0xFFF0997B).withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Text('$icon $need',
        style: TextStyle(
          fontSize: 12,
          color: enough
              ? const Color(0xFF5DCAA5)
              : const Color(0xFFF0997B),
          fontWeight: FontWeight.w500,
        )),
    );
  }
}

int _getTabIndex() {
    switch (building.buildingType) {
      case 'barracks':
      case 'elephant_camp': return 2; // tab ทหาร
      case 'sawmill':
      case 'smelter':
      case 'rice_farm':
      case 'distillery':    return 1; // tab อาคาร
      case 'town_hall':     return 1;
      default:              return 0;
    }
  }