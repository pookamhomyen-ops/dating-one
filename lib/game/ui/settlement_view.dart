import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../providers/game_providers.dart';
import '../models/building.dart';
import '../models/settlement.dart';
import '../services/building_service.dart';
import 'arrange_buildings_view.dart';
import '../models/quest.dart';

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
class _SettlementScene extends ConsumerWidget {
  final Settlement settlement;
  final List<Building> buildings;
  final void Function(int)? onSwitchTab;
  const _SettlementScene({
    required this.settlement,
    required this.buildings,
    this.onSwitchTab,
  });

  // ขอบเขตพื้นที่ (fraction) สำหรับแปลง grid <-> offset
  static const double _left = 0.10;
  static const double _right = 0.90;
  static const double _top = 0.20;
  static const double _bottom = 0.90;
  static const int _gridSize = 20;

  static Offset _gridToOffset(int x, int y) {
    return Offset(
      _left + (x / _gridSize) * (_right - _left),
      _top + (y / _gridSize) * (_bottom - _top),
    );
  }

  // hardcoded fallback
  static const _positions = <String, Offset>{
    'town_hall':      Offset(0.42, 0.32),
    'barracks':       Offset(0.62, 0.52),
    'sawmill':        Offset(0.25, 0.38),
    'smelter':        Offset(0.68, 0.36),
    'rice_farm':      Offset(0.28, 0.62),
    'distillery':     Offset(0.58, 0.68),
    'house':          Offset(0.42, 0.55),
    'tavern':         Offset(0.50, 0.44),
    'shrine':         Offset(0.72, 0.60),
    'elephant_camp':  Offset(0.22, 0.52),
    'smithy':         Offset(0.65, 0.44),
    'wall':           Offset(0.35, 0.46),
    'watchtower':     Offset(0.55, 0.38),
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

  int _getTabIndex() => 0;
void _showQuestSheet(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5EFE6),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: _QuestSheet(settlement: settlement),
      ),
    );
  }
  // แทนที่ build method ของ _SettlementScene ด้วยโค้ดนี้
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionsAsync = ref.watch(buildingPositionsProvider);
    final positionsMap = <String, Offset>{};

    positionsAsync.maybeWhen(
      data: (posList) {
        for (var b in buildings) {
          final found = posList.firstWhereOrNull((p) => p.buildingId == b.id);
          if (found != null) {
            positionsMap[b.id] = _gridToOffset(found.posX, found.posY);
          } else {
            final defaultOffset = _positions[b.buildingType];
            if (defaultOffset != null) {
              positionsMap[b.id] = defaultOffset;
            }
          }
        }
      },
      orElse: () {
        for (var b in buildings) {
          final defaultOffset = _positions[b.buildingType];
          if (defaultOffset != null) {
            positionsMap[b.id] = defaultOffset;
          }
        }
      },
    );

    return Stack(
      children: [
        _AyutthayaBackground(),
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: _TopBar(settlement: settlement),
          ),
        ),
        ...buildings.map((b) {
          final pos = positionsMap[b.id];
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
        Positioned(
          top: 0, left: 0,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                color: Color(0xFFFAC775), size: 20),
              onPressed: () {
                Navigator.pop(context);
                onSwitchTab?.call(_getTabIndex());
              },
            ),
          ),
        ),
        // แทนที่ Positioned ของปุ่ม arrangeBtn ด้วยอันนี้
Positioned(
  bottom: 16,
  right: 16,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FloatingActionButton.small(
        heroTag: 'questBtn',
        backgroundColor: const Color(0xFF3C2810),
        onPressed: () => _showQuestSheet(context),
        child: const Text('📜', style: TextStyle(fontSize: 16)),
      ),
      const SizedBox(height: 8),
      FloatingActionButton.small(
        heroTag: 'arrangeBtn',
        backgroundColor: const Color(0xFF854F0B),
        onPressed: () {
          final container = ProviderScope.containerOf(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UncontrolledProviderScope(
                container: container,
                child: ArrangeBuildingsView(
                  settlement: settlement,
                  buildings: buildings,
                ),
              ),
            ),
          );
        },
        child: const Icon(Icons.edit, color: Colors.white, size: 20),
      ),
    ],
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
            errorBuilder: (context, e, s) => Image.asset(
              'assets/games/bg/bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, e, s) => Container(
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

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends ConsumerWidget {
  final Settlement settlement;
  const _TopBar({required this.settlement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thLevel   = ref.watch(townHallLevelProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(44, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF8B6914).withValues(alpha: 0.5), width: 0.5),
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
              color: const Color(0xFF854F0B).withValues(alpha: 0.6),
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
                                width: 100, height: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (context, e, s) => Text(emoji,
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
                                color: const Color(0xFFF0997B).withValues(alpha: 0.85),
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
                            color: const Color(0xFFF0997B).withValues(alpha: 0.9),
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
                    color: Colors.black.withValues(alpha: 0.55),
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
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
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
                color: const Color(0xFF5DCAA5).withValues(alpha: 0.15),
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
            color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
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
            ? const Color(0xFF0F6E56).withValues(alpha: 0.3)
            : const Color(0xFFA32D2D).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: enough
              ? const Color(0xFF5DCAA5).withValues(alpha: 0.4)
              : const Color(0xFFF0997B).withValues(alpha: 0.4),
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

// ─── Quest Sheet ──────────────────────────────────────────────────────────────
// วางต่อท้าย settlement_view.dart

class _QuestSheet extends ConsumerWidget {
  final Settlement settlement;
  const _QuestSheet({required this.settlement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsWithProgress = ref.watch(questsWithProgressProvider);
    final daily   = questsWithProgress.where((q) => q.quest.questType == 'daily').toList();
    final weekly  = questsWithProgress.where((q) => q.quest.questType == 'weekly').toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                const Text('📜', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text('ภารกิจ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                // badge จำนวน ready to claim
                Builder(builder: (_) {
                  final ready = questsWithProgress
                      .where((q) => q.isReadyToClaim).length;
                  if (ready == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF993C1D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$ready รอรับรางวัล',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11)),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(12),
              children: [
                if (daily.isNotEmpty) ...[
                  _SectionLabel(label: '📅 ภารกิจรายวัน'),
                  ...daily.map((q) => _QuestCard(
                    questWithProgress: q,
                    settlement: settlement,
                  )),
                  const SizedBox(height: 8),
                ],
                if (weekly.isNotEmpty) ...[
                  _SectionLabel(label: '📆 ภารกิจรายสัปดาห์'),
                  ...weekly.map((q) => _QuestCard(
                    questWithProgress: q,
                    settlement: settlement,
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        )),
    );
  }
}

class _QuestCard extends ConsumerWidget {
  final QuestWithProgress questWithProgress;
  final Settlement settlement;
  const _QuestCard({
    required this.questWithProgress,
    required this.settlement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q    = questWithProgress.quest;
    final qwp  = questWithProgress;

    Color borderColor;
    Color bgColor;
    if (qwp.isClaimed) {
      borderColor = Colors.grey[300]!;
      bgColor     = Colors.grey[50]!;
    } else if (qwp.isReadyToClaim) {
      borderColor = const Color(0xFF5DCAA5);
      bgColor     = const Color(0xFF5DCAA5).withValues(alpha: 0.06);
    } else {
      borderColor = Colors.black.withValues(alpha: 0.08);
      bgColor     = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: qwp.isClaimed
                              ? Colors.grey[400]
                              : Colors.black87,
                          decoration: qwp.isClaimed
                              ? TextDecoration.lineThrough
                              : null,
                        )),
                      const SizedBox(height: 2),
                      Text(q.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // claim / status button
                if (qwp.isClaimed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('✅ รับแล้ว',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500])),
                  )
                else if (qwp.isReadyToClaim)
                  GestureDetector(
                    onTap: () => _claim(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5DCAA5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('🎁 รับรางวัล',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        )),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // progress bar
            if (!qwp.isClaimed) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: qwp.progressFraction,
                        minHeight: 5,
                        backgroundColor: Colors.black.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation(
                          qwp.isCompleted
                              ? const Color(0xFF5DCAA5)
                              : const Color(0xFFFAC775),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${qwp.currentAmount}/${q.requirementAmount}',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // rewards
            Row(
              children: [
                Text('รางวัล: ',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                if (q.rewardWood > 0)   _RewardChip(icon: '🪵', value: q.rewardWood),
                if (q.rewardIron > 0)   _RewardChip(icon: '⚙️', value: q.rewardIron),
                if (q.rewardRice > 0)   _RewardChip(icon: '🌾', value: q.rewardRice),
                if (q.rewardLiquor > 0) _RewardChip(icon: '🍶', value: q.rewardLiquor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    try {
      final gameClient = ref.read(gameSupabaseProvider);
      await gameClient.rpc('claim_quest_reward', params: {
        'p_settlement_id': settlement.id,
        'p_quest_id': questWithProgress.quest.id,
      });
      ref.invalidate(questProgressProvider);
      ref.invalidate(settlementProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎁 รับรางวัลเรียบร้อย!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('รับรางวัลไม่ได้: $e')),
        );
      }
    }
  }
}

class _RewardChip extends StatelessWidget {
  final String icon;
  final int value;
  const _RewardChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text('$icon$value',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}
