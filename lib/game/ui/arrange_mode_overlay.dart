import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../models/building.dart';
import '../models/settlement.dart';
import '../models/building_position.dart';
import '../providers/game_providers.dart';

/// โหมดจัดวางตำแหน่งอาคาร แสดงทับบน SettlementView โดยตรง (ไม่ push หน้าใหม่ เพื่อความเร็ว)
/// ระบบกริด: สี่เหลี่ยมตรง เต็มความกว้างจอ เว้นขอบบน 10% และขอบล่าง 10%
class ArrangeModeOverlay extends ConsumerStatefulWidget {
  final Settlement settlement;
  final List<Building> buildings;
  final bool showGrid;
  final VoidCallback onExit;

  const ArrangeModeOverlay({
    super.key,
    required this.settlement,
    required this.buildings,
    required this.showGrid,
    required this.onExit,
  });

  @override
  ConsumerState<ArrangeModeOverlay> createState() => _ArrangeModeOverlayState();
}

class _ArrangeModeOverlayState extends ConsumerState<ArrangeModeOverlay> {
  // ขอบเขตกริด: เต็มความกว้าง (0.0-1.0), สูงเว้นบน 10% ล่าง 10%
  static const double _marginTop = 0.10;
  static const double _marginBottom = 0.10;
  static const int _gridSize = 20;

  // อาคาร 1 หลัง ยึด 3 cols x 2 rows, anchor = กลางล่าง
  static const int _bldW = 3;
  static const int _bldH = 2;

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

  // grid (x,y) -> offset สัดส่วนจอ (0.0-1.0) แบบเส้นตรง (linear)
  static Offset _gridToOffset(int x, int y) {
    final dx = x / _gridSize;
    final dy = _marginTop + (y / _gridSize) * (1 - _marginTop - _marginBottom);
    return Offset(dx, dy);
  }

  // offset สัดส่วนจอ -> grid (x,y)
  static ({int x, int y}) _offsetToGrid(Offset offset) {
    final u = offset.dx;
    final v = (offset.dy - _marginTop) / (1 - _marginTop - _marginBottom);
    final x = (u * _gridSize).round().clamp(0, _gridSize - 1);
    final y = (v * _gridSize).round().clamp(0, _gridSize - 1);
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
    if (posList.isNotEmpty && mounted) {
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

  bool _canPlace(int ax, int ay, String excludeId) {
    final cells = _occupiedCells(ax, ay);
    for (final cell in cells) {
      if (cell.x < 0 || cell.x >= _gridSize || cell.y < 0 || cell.y >= _gridSize) {
        return false;
      }
      for (final entry in _positions.entries) {
        if (entry.key == excludeId) continue;
        final otherCells = _occupiedCells(entry.value.x, entry.value.y);
        if (otherCells.any((c) => c.x == cell.x && c.y == cell.y)) return false;
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
      if (nextX < 0 || nextX >= _gridSize || nextY < 0 || nextY >= _gridSize) return;
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
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Container(color: Colors.black.withValues(alpha: 0.15)),
          ),
        ),
        if (widget.showGrid)
          Positioned.fill(
            child: IgnorePointer(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: CustomPaint(
                  painter: _ArrangeGridPainter(
                    gridSize: _gridSize,
                    marginTop: _marginTop,
                    marginBottom: _marginBottom,
                  ),
                ),
              ),
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
            selected: isSelected,
            onTap: () {
              setState(() {
                _selectedBuildingId = (_selectedBuildingId == b.id) ? null : b.id;
              });
            },
          );
        }),
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
        if (_selectedBuildingId == null)
          Positioned(
            bottom: 16,
            left: 16,
            child: SafeArea(
              top: false,
              child: ElevatedButton.icon(
                onPressed: widget.onExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF854F0B).withValues(alpha: 0.85),
                  foregroundColor: const Color(0xFFFAC775),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('ย้อนกลับ'),
              ),
            ),
          ),
      ],
    );
  }
}

class _ArrangeGridPainter extends CustomPainter {
  final int gridSize;
  final double marginTop;
  final double marginBottom;

  const _ArrangeGridPainter({
    required this.gridSize,
    required this.marginTop,
    required this.marginBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    final majorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.3;

    final top = size.height * marginTop;
    final bottom = size.height * (1 - marginBottom);
    final gridHeight = bottom - top;
    final cellW = size.width / gridSize;
    final cellH = gridHeight / gridSize;

    for (int i = 0; i <= gridSize; i++) {
      final x = i * cellW;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), i % 5 == 0 ? majorPaint : gridPaint);
    }
    for (int i = 0; i <= gridSize; i++) {
      final y = top + i * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), i % 5 == 0 ? majorPaint : gridPaint);
    }

    // เลขไล่ 1..400 ในแต่ละช่อง (ซ้าย->ขวา, บน->ล่าง)
    int number = 1;
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final cx = col * cellW + cellW / 2;
        final cy = top + row * cellH + cellH / 2;
        _drawNumber(canvas, '$number', Offset(cx, cy));
        number++;
      }
    }
  }

  void _drawNumber(Canvas canvas, String text, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 7,
          fontWeight: FontWeight.w600,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ArrangeGridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize ||
        oldDelegate.marginTop != marginTop ||
        oldDelegate.marginBottom != marginBottom;
  }
}
class _ArrangeBuildingIcon extends StatelessWidget {
  final Building building;
  final Offset offset;
  final bool selected;
  final VoidCallback onTap;

  const _ArrangeBuildingIcon({
    required this.building,
    required this.offset,
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
        child: Container(
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
        border: const Border(top: BorderSide(color: Color(0xFF8B6914), width: 1)),
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
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Center(
                    child: _ArrowButton(icon: Icons.arrow_upward_rounded, onTap: () => onMove(0, -1)),
                  ),
                ),
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  child: Center(
                    child: _ArrowButton(icon: Icons.arrow_back_rounded, onTap: () => onMove(-1, 0)),
                  ),
                ),
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D1F08).withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF8B6914).withValues(alpha: 0.6), width: 1),
                  ),
                  child: Center(
                    child: Text(_buildingEmoji(selectedBuilding.buildingType), style: const TextStyle(fontSize: 22)),
                  ),
                ),
                Positioned(
                  right: 0, top: 0, bottom: 0,
                  child: Center(
                    child: _ArrowButton(icon: Icons.arrow_forward_rounded, onTap: () => onMove(1, 0)),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Center(
                    child: _ArrowButton(icon: Icons.arrow_downward_rounded, onTap: () => onMove(0, 1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF854F0B).withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFAC775), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}