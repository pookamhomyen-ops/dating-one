import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/building.dart';
import '../models/settlement.dart';
import '../models/building_position.dart';
import '../providers/game_providers.dart';

class ArrangeBuildingsView extends ConsumerStatefulWidget {
  final Settlement settlement;
  final List<Building> buildings;
  const ArrangeBuildingsView({
    super.key,
    required this.settlement,
    required this.buildings,
  });

  @override
  ConsumerState<ArrangeBuildingsView> createState() =>
      _ArrangeBuildingsViewState();
}

class _ArrangeBuildingsViewState extends ConsumerState<ArrangeBuildingsView> {
  static const double _left = 0.10;
  static const double _right = 0.90;
  static const double _top = 0.20;
  static const double _bottom = 0.90;
  static const int _gridSize = 20;

  static const _defaultOffsets = <String, Offset>{
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

  static Offset _gridToOffset(int x, int y) {
    return Offset(
      _left + (x / _gridSize) * (_right - _left),
      _top + (y / _gridSize) * (_bottom - _top),
    );
  }

  static ({int x, int y}) _offsetToGrid(Offset offset) {
    final x = ((offset.dx - _left) / (_right - _left) * _gridSize)
        .round()
        .clamp(0, _gridSize - 1);
    final y = ((offset.dy - _top) / (_bottom - _top) * _gridSize)
        .round()
        .clamp(0, _gridSize - 1);
    return (x: x, y: y);
  }

  late Map<String, ({int x, int y})> _positions;
  late Map<String, ({int x, int y})> _originalPositions;
  String? _selectedBuildingId;

  @override
  void initState() {
    super.initState();
    _positions = _buildDefaultPositions();
    _originalPositions = Map.from(_positions);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPositionsFromDb());
  }

  Map<String, ({int x, int y})> _buildDefaultPositions() {
    final result = <String, ({int x, int y})>{};
    for (var b in widget.buildings) {
      final offset = _defaultOffsets[b.buildingType];
      if (offset != null) {
        result[b.id] = _offsetToGrid(offset);
      } else {
        result[b.id] = (x: 10, y: 10);
      }
    }
    return result;
  }

  Future<void> _loadPositionsFromDb() async {
    final posList = await ref.read(buildingPositionsProvider.future);
    if (posList.isNotEmpty) {
      setState(() {
        for (var p in posList) {
          _positions[p.buildingId] = (x: p.posX, y: p.posY);
          _originalPositions[p.buildingId] = (x: p.posX, y: p.posY);
        }
      });
    }
  }

  bool _isOccupied(int x, int y, String excludeBuildingId) {
    return _positions.entries.any((entry) =>
        entry.key != excludeBuildingId &&
        entry.value.x == x &&
        entry.value.y == y);
  }

  void _tryMove(String buildingId, int dx, int dy) {
    final current = _positions[buildingId];
    if (current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบอาคาร')),
      );
      return;
    }

    int targetX = current.x;
    int targetY = current.y;

    // ข้ามสิ่งกีดขวางไปเรื่อยๆ จนกว่าจะเจอช่องว่างหรือถึงขอบ
    while (true) {
      final nextX = targetX + dx;
      final nextY = targetY + dy;
      if (nextX < 0 || nextX >= _gridSize || nextY < 0 || nextY >= _gridSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ถึงขอบเขตแล้ว')),
        );
        return;
      }
      if (!_isOccupied(nextX, nextY, buildingId)) {
        // เจอช่องว่าง
        targetX = nextX;
        targetY = nextY;
        break;
      }
      // มีสิ่งกีดขวาง ข้ามไป
      targetX = nextX;
      targetY = nextY;
      // continue loop
    }

    if (targetX != current.x || targetY != current.y) {
      setState(() {
        _positions[buildingId] = (x: targetX, y: targetY);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ย้ายไป ($targetX,$targetY)')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถย้ายได้')),
      );
    }
  }

  void _cancel() {
    setState(() {
      _positions = Map.from(_originalPositions);
      _selectedBuildingId = null;
    });
  }

  Future<void> _saveAndPop() async {
    try {
      final positionsList = _positions.entries.map((entry) {
        return BuildingPosition(
          id: '',
          settlementId: widget.settlement.id,
          buildingId: entry.key,
          posX: entry.value.x,
          posY: entry.value.y,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();

      final service = ref.read(buildingPositionServiceProvider);
      await service.savePositions(positionsList);
      ref.invalidate(buildingPositionsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e, stack) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double? selLeft;
    double? selTop;

    if (_selectedBuildingId != null) {
      final pos = _positions[_selectedBuildingId!];
      if (pos != null) {
        final offset = _gridToOffset(pos.x, pos.y);
        selLeft = offset.dx * size.width - 28;
        selTop = offset.dy * size.height - 40;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2A1A08),
      body: Stack(
        children: [
          _AyutthayaBackground(),
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(gridSize: _gridSize),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: _TopBar(settlement: widget.settlement),
            ),
          ),
          ...widget.buildings.map((b) {
            final pos = _positions[b.id];
            if (pos == null) return const SizedBox.shrink();
            final offset = _gridToOffset(pos.x, pos.y);
            final isSelected = _selectedBuildingId == b.id;
            return _ArrangeBuildingIcon(
              building: b,
              offset: offset,
              gridX: pos.x,
              gridY: pos.y,
              selected: isSelected,
              onTap: () {
                setState(() {
                  if (_selectedBuildingId == b.id) {
                    _selectedBuildingId = null;
                  } else {
                    _selectedBuildingId = b.id;
                  }
                });
              },
            );
          }),
          if (selLeft != null && selTop != null) ...[
            Positioned(
              top: selTop - 32,
              left: selLeft + 16,
              child: _ArrowButton(
                icon: Icons.arrow_upward,
                onTap: () => _tryMove(_selectedBuildingId!, 0, -1),
              ),
            ),
            Positioned(
              top: selTop + 62,
              left: selLeft + 16,
              child: _ArrowButton(
                icon: Icons.arrow_downward,
                onTap: () => _tryMove(_selectedBuildingId!, 0, 1),
              ),
            ),
            Positioned(
              top: selTop + 16,
              left: selLeft - 32,
              child: _ArrowButton(
                icon: Icons.arrow_back,
                onTap: () => _tryMove(_selectedBuildingId!, -1, 0),
              ),
            ),
            Positioned(
              top: selTop + 16,
              left: selLeft + 62,
              child: _ArrowButton(
                icon: Icons.arrow_forward,
                onTap: () => _tryMove(_selectedBuildingId!, 1, 0),
              ),
            ),
          ],
          if (_selectedBuildingId != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8B6914)),
                      foregroundColor: const Color(0xFFFAC775),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _saveAndPop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5DCAA5),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('บันทึก'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int gridSize;
  const _GridPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    final left = size.width * 0.10;
    final right = size.width * 0.90;
    final top = size.height * 0.20;
    final bottom = size.height * 0.90;
    final cellW = (right - left) / gridSize;
    final cellH = (bottom - top) / gridSize;

    for (int i = 0; i <= gridSize; i++) {
      final x = left + i * cellW;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
    for (int i = 0; i <= gridSize; i++) {
      final y = top + i * cellH;
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

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
            errorBuilder: (_, _, __) => Image.asset(
              'assets/games/bg/bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, __) => Container(
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
      ],
    );
  }
}

class _TopBar extends ConsumerWidget {
  final Settlement settlement;
  const _TopBar({required this.settlement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thLevel = ref.watch(townHallLevelProvider);

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

class _ArrangeBuildingIcon extends StatelessWidget {
  final Building building;
  final Offset offset;
  final int gridX;
  final int gridY;
  final bool selected;
  final VoidCallback onTap;

  const _ArrangeBuildingIcon({
    required this.building,
    required this.offset,
    required this.gridX,
    required this.gridY,
    required this.selected,
    required this.onTap,
  });

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
  static const _assetPath = 'assets/games/buildings';

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
    final size = MediaQuery.of(context).size;
    final left = offset.dx * size.width - 28;
    final top  = offset.dy * size.height - 40;
    final imagePath = _getImagePath(building);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                border: selected
                    ? Border.all(color: const Color(0xFFFAC775), width: 2)
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  imagePath.isNotEmpty
                      ? Image.asset(
                          imagePath,
                          width: 60, height: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, __) => Text(
                            _emoji[building.buildingType] ?? '🏛️',
                            style: const TextStyle(fontSize: 36),
                          ),
                        )
                      : Text(
                          _emoji[building.buildingType] ?? '🏛️',
                          style: const TextStyle(fontSize: 36),
                        ),
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
                          '⏳',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8, color: Colors.white,
                            fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${building.displayName} ${building.level}',
                    style: const TextStyle(
                      color: Color(0xFFFAC775), fontSize: 8),
                  ),
                  Text(
                    '($gridX,$gridY)',
                    style: const TextStyle(
                      color: Colors.white70, fontSize: 7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF854F0B).withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFAC775), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}