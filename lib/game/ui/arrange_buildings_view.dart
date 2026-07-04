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
  // boundary ในหน่วย fraction ของหน้าจอ
  static const Offset _vTop = Offset(0.503, 0.066);
  static const Offset _vRight = Offset(0.992, 0.444);
  static const Offset _vBottom = Offset(0.519, 0.860);
  static const Offset _vLeft = Offset(0.026, 0.324);
  static const int _gridSize = 20;

  // อาคาร 1 หลัง ยึด 3 cols x 2 rows, anchor = กลางล่าง
  static const int _bldW = 3; // แนวนอน
  static const int _bldH = 2; // แนวตั้ง

  static const _defaultOffsets = <String, Offset>{
    'town_hall': Offset(0.42, 0.32),
    'barracks': Offset(0.62, 0.52),
    'sawmill': Offset(0.25, 0.38),
    'smelter': Offset(0.68, 0.36),
    'rice_farm': Offset(0.28, 0.62),
    'distillery': Offset(0.58, 0.68),
    'house': Offset(0.42, 0.55),
    'tavern': Offset(0.50, 0.44),
    'shrine': Offset(0.72, 0.60),
    'elephant_camp': Offset(0.22, 0.52),
    'smithy': Offset(0.65, 0.44),
    'wall': Offset(0.35, 0.46),
    'watchtower': Offset(0.55, 0.38),
  };

  static Offset _gridToOffset(int x, int y) {
    final u = x / _gridSize;
    final v = y / _gridSize;
    final dx =
        (1 - u) * (1 - v) * _vTop.dx +
        u * (1 - v) * _vRight.dx +
        (1 - u) * v * _vLeft.dx +
        u * v * _vBottom.dx;
    final dy =
        (1 - u) * (1 - v) * _vTop.dy +
        u * (1 - v) * _vRight.dy +
        (1 - u) * v * _vLeft.dy +
        u * v * _vBottom.dy;
    return Offset(dx, dy);
  }

  static ({int x, int y}) _offsetToGrid(Offset offset) {
    // ผกผันแบบเชิงเส้น โดยใช้ top เป็นจุดอ้างอิง แกน u=top->right, v=top->left
    final ux = _vRight.dx - _vTop.dx, uy = _vRight.dy - _vTop.dy;
    final vx = _vLeft.dx - _vTop.dx, vy = _vLeft.dy - _vTop.dy;
    final px = offset.dx - _vTop.dx, py = offset.dy - _vTop.dy;
    final det = ux * vy - uy * vx;
    final u = (px * vy - py * vx) / det;
    final v = (ux * py - uy * px) / det;
    final x = (u * _gridSize).round().clamp(1, _gridSize - 2);
    final y = (v * _gridSize).round().clamp(1, _gridSize - 1);
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
        result[b.id] = (x: 5, y: 5);
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

  // คืน list ของ cells ทั้งหมดที่อาคารยึด จาก anchor (กลางล่าง)
  static List<({int x, int y})> _occupiedCells(int ax, int ay) {
    final cells = <({int x, int y})>[];
    for (int row = 0; row < _bldH; row++) {
      for (int col = -(_bldW ~/ 2); col <= _bldW ~/ 2; col++) {
        cells.add((x: ax + col, y: ay - row));
      }
    }
    return cells;
  }

  // เช็คว่า cells ทั้งหมดของอาคารที่ anchor ใหม่ ไม่ชนกับอาคารอื่น
  bool _canPlace(int ax, int ay, String excludeId) {
    final cells = _occupiedCells(ax, ay);
    for (final cell in cells) {
      if (cell.x < 0 ||
          cell.x >= _gridSize ||
          cell.y < 0 ||
          cell.y >= _gridSize)
        return false;
      if (!_isInsideOval(cell.x, cell.y)) return false;
      // เช็คชนกับอาคารอื่น
      for (final entry in _positions.entries) {
        if (entry.key == excludeId) continue;
        final otherCells = _occupiedCells(entry.value.x, entry.value.y);
        if (otherCells.any((c) => c.x == cell.x && c.y == cell.y)) return false;
      }
    }
    return true;
  }

  static bool _isInsideOval(int x, int y) {
    final p = _gridToOffset(x, y);
    const verts = [_vTop, _vRight, _vBottom, _vLeft];
    int sign = 0;
    for (int i = 0; i < 4; i++) {
      final v1 = verts[i], v2 = verts[(i + 1) % 4];
      final cross =
          (v2.dx - v1.dx) * (p.dy - v1.dy) - (v2.dy - v1.dy) * (p.dx - v1.dx);
      final s = cross > 0 ? 1 : (cross < 0 ? -1 : 0);
      if (s != 0) {
        if (sign == 0)
          sign = s;
        else if (s != sign)
          return false;
      }
    }
    return true;
  }

  void _tryMove(String buildingId, int dx, int dy) {
    final current = _positions[buildingId];
    if (current == null) return;

    int nextX = current.x + dx;
    int nextY = current.y + dy;

    while (true) {
      if (nextX < 0 || nextX >= _gridSize || nextY < 0 || nextY >= _gridSize)
        return;
      if (_canPlace(nextX, nextY, buildingId)) break;
      nextX += dx;
      nextY += dy;
    }

    setState(() {
      _positions[buildingId] = (x: nextX, y: nextY);
    });
  }

  void _cancel() {
    setState(() {
      _positions = Map.from(_originalPositions);
      _selectedBuildingId = null;
    });
  }

  Future<void> _place() async {
    final id = _selectedBuildingId;
    final pos = id != null ? _positions[id] : null;
    if (id == null || pos == null) return;
    try {
      final service = ref.read(buildingPositionServiceProvider);
      await service.savePositions([
        BuildingPosition(
          id: '',
          settlementId: widget.settlement.id,
          buildingId: id,
          posX: pos.x,
          posY: pos.y,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);
      ref.invalidate(buildingPositionsProvider);
      if (mounted) {
        setState(() {
          _originalPositions[id] = pos;
          _selectedBuildingId = null;
        });
      }
    } catch (e) {
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

    final uPx = Offset(
      (_vRight.dx - _vTop.dx) * size.width,
      (_vRight.dy - _vTop.dy) * size.height,
    ).distance;
    final vPx = Offset(
      (_vLeft.dx - _vTop.dx) * size.width,
      (_vLeft.dy - _vTop.dy) * size.height,
    ).distance;
    final cellSize = (uPx < vPx ? uPx : vPx) / _gridSize;

    return Scaffold(
      backgroundColor: const Color(0xFF2A1A08),
      body: Stack(
        children: [
          _AyutthayaBackground(),
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(gridSize: _gridSize, cellSize: cellSize),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _TopBar(settlement: widget.settlement)),
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
              cellSize: cellSize,
              selected: isSelected,
              onTap: () {
                setState(() {
                  _selectedBuildingId = (_selectedBuildingId == b.id)
                      ? null
                      : b.id;
                });
              },
            );
          }),
          // Bottom control panel - แสดงเฉพาะตอนเลือกอาคาร
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomControlPanel(
              selectedBuildingId: _selectedBuildingId,
              buildings: widget.buildings,
              onMove: (dx, dy) => _tryMove(_selectedBuildingId!, dx, dy),
              onCancel: _cancel,
              onSave: _place,
            ),
          ),
          // ปุ่มย้อนกลับ - แสดงเฉพาะตอนยังไม่ได้เลือกอาคาร
          if (_selectedBuildingId == null)
            Positioned(
              bottom: 16,
              left: 16,
              child: SafeArea(
                top: false,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF854F0B).withValues(alpha: 0.85),
                    foregroundColor: const Color(0xFFFAC775),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('ย้อนกลับ'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int gridSize;
  final double cellSize; // เก็บไว้เพื่อไม่กระทบจุดเรียกใช้เดิม (ไม่ใช้ในนี้แล้ว)
  const _GridPainter({required this.gridSize, required this.cellSize});

  static const Offset _vTop    = Offset(0.503, 0.066);
  static const Offset _vRight  = Offset(0.992, 0.444);
  static const Offset _vBottom = Offset(0.519, 0.860);
  static const Offset _vLeft   = Offset(0.026, 0.324);

  Offset _toPixel(double u, double v, Size size) {
    final dx = (1 - u) * (1 - v) * _vTop.dx + u * (1 - v) * _vRight.dx
             + (1 - u) * v * _vLeft.dx      + u * v * _vBottom.dx;
    final dy = (1 - u) * (1 - v) * _vTop.dy + u * (1 - v) * _vRight.dy
             + (1 - u) * v * _vLeft.dy      + u * v * _vBottom.dy;
    return Offset(dx * size.width, dy * size.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.0;
    final majorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;

    const segments = 6; // ย่อยเส้นเป็นช่วงๆ ให้โค้งตามขอบ diamond จริง

    for (int i = 0; i <= gridSize; i++) {
      final v = i / gridSize;
      final path = Path();
      for (int s = 0; s <= segments; s++) {
        final p = _toPixel(s / segments, v, size);
        s == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, i % 5 == 0 ? majorPaint : gridPaint);
    }

    for (int i = 0; i <= gridSize; i++) {
      final u = i / gridSize;
      final path = Path();
      for (int s = 0; s <= segments; s++) {
        final p = _toPixel(u, s / segments, size);
        s == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, i % 5 == 0 ? majorPaint : gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AyutthayaBackground extends ConsumerWidget {
  const _AyutthayaBackground();

  String _getBgPath(String season) {
    switch (season) {
      case 'summer':
        return 'assets/games/bg/bg_summer.png';
      case 'rain':
        return 'assets/games/bg/bg_rain.png';
      case 'winter':
        return 'assets/games/bg/bg_winter.png';
      default:
        return 'assets/games/bg/bg.png';
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
            errorBuilder: (_, _, _) => Image.asset(
              'assets/games/bg/bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A0F05),
                      Color(0xFF3D1F08),
                      Color(0xFF5C3210),
                      Color(0xFF4A6741),
                    ],
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
          color: const Color(0xFF8B6914).withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Text(
            settlement.name,
            style: const TextStyle(
              color: Color(0xFFFAC775),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF854F0B).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '🏛️ Lv.$thLevel',
              style: const TextStyle(color: Color(0xFFFAC775), fontSize: 10),
            ),
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
    return Text(
      '$icon$value',
      style: const TextStyle(color: Color(0xFFFAC775), fontSize: 10),
    );
  }
}

class _ArrangeBuildingIcon extends StatelessWidget {
  final Building building;
  final Offset offset;
  final int gridX;
  final int gridY;
  final double cellSize;
  final bool selected;
  final VoidCallback onTap;

  const _ArrangeBuildingIcon({
    required this.building,
    required this.offset,
    required this.gridX,
    required this.gridY,
    required this.cellSize,
    required this.selected,
    required this.onTap,
  });

  static const _imageMap = <String, String>{
    'town_hall': 'town_hall.webp',
    'barracks': 'barracks.webp',
    'sawmill': 'sawmill.webp',
    'smelter': 'smelter.webp',
    'rice_farm': 'rice_farm.webp',
    'shrine': 'shrine.webp',
  };
  static const _emoji = <String, String>{
    'distillery': '🍶',
    'house': '🏠',
    'tavern': '🍺',
    'elephant_camp': '🐘',
    'smithy': '🔨',
    'wall': '🧱',
    'watchtower': '🗼',
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
    final top = offset.dy * size.height - 40;
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
              child: imagePath.isNotEmpty
                  ? Image.asset(
                      imagePath,
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Text(
                        _emoji[building.buildingType] ?? '🏛️',
                        style: const TextStyle(fontSize: 36),
                      ),
                    )
                  : Text(
                      _emoji[building.buildingType] ?? '🏛️',
                      style: const TextStyle(fontSize: 36),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomControlPanel extends StatelessWidget {
  final String? selectedBuildingId;
  final List<Building> buildings;
  final void Function(int dx, int dy) onMove;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _BottomControlPanel({
    required this.selectedBuildingId,
    required this.buildings,
    required this.onMove,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBuilding = selectedBuildingId != null
        ? buildings.where((b) => b.id == selectedBuildingId).firstOrNull
        : null;

    if (selectedBuilding == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        border: const Border(
          top: BorderSide(color: Color(0xFF8B6914), width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 12,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ชื่ออาคารที่เลือก + ลูกศร D-pad
          if (selectedBuilding != null) ...[
            // ป้ายชื่ออาคาร
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF854F0B).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFAC775), width: 0.8),
              ),
              child: Text(
                '${selectedBuilding.displayName} Lv.${selectedBuilding.level}  —  กดลูกศรเพื่อย้ายตำแหน่ง',
                style: const TextStyle(
                  color: Color(0xFFFAC775),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // D-pad ลูกศร 4 ทิศ
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ขึ้น
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _ArrowButton(
                        icon: Icons.arrow_upward_rounded,
                        onTap: () => onMove(0, -1),
                      ),
                    ),
                  ),
                  // ซ้าย
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _ArrowButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => onMove(-1, 0),
                      ),
                    ),
                  ),
                  // กลาง - ไอคอนอาคาร
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D1F08).withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF8B6914).withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _buildingEmoji(selectedBuilding.buildingType),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  // ขวา
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _ArrowButton(
                        icon: Icons.arrow_forward_rounded,
                        onTap: () => onMove(1, 0),
                      ),
                    ),
                  ),
                  // ลง
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _ArrowButton(
                        icon: Icons.arrow_downward_rounded,
                        onTap: () => onMove(0, 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ปุ่มยกเลิก + บันทึก (แสดงเสมอ)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF8B6914)),
                    foregroundColor: const Color(0xFFFAC775),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('ยกเลิก'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5DCAA5),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('วาง'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildingEmoji(String type) {
    const emojis = {
      'town_hall': '🏛️',
      'barracks': '⚔️',
      'sawmill': '🪵',
      'smelter': '🔥',
      'rice_farm': '🌾',
      'distillery': '🍶',
      'house': '🏠',
      'tavern': '🍺',
      'shrine': '⛩️',
      'elephant_camp': '🐘',
      'smithy': '🔨',
      'wall': '🧱',
      'watchtower': '🗼',
    };
    return emojis[type] ?? '🏛️';
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF854F0B).withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFAC775), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}