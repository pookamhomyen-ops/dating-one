import 'dart:async';
import 'package:flutter/material.dart';

/// ข้อมูล grid ของ sprite sheet แต่ละไฟล์ (แต่ละไฟล์ขนาด/จำนวนเฟรมไม่เท่ากันได้)
class _SheetInfo {
  final String path;
  final int cols;
  final int rows;
  final double sheetW;
  final double sheetH;
  final int validFrames; // จำนวนเฟรมที่ "มีตัวละครจริง" ไม่นับช่องว่างท้าย grid
  double get frameW => sheetW / cols;
  double get frameH => sheetH / rows;
  int get totalFrames => validFrames;

  const _SheetInfo({
    required this.path,
    required this.cols,
    required this.rows,
    required this.sheetW,
    required this.sheetH,
    required this.validFrames,
  });
}

/// NPC เดินตกแต่งฉาก settlement — ไม่ผูกกับ DB/gameplay ใดๆ
/// เดินจากอาคาร "ซ้ายบนสุด" ไป "ขวาล่างสุด" (คำนวณใหม่ทุกรอบ เผื่อผู้เล่นย้ายตึก)
/// หลบตึกที่ขวางเส้นทาง แล้วสลับทิศไป-กลับทุกรอบ
class WalkingVillager extends StatefulWidget {
  final Map<String, Offset> buildingPositions; // fractional (dx,dy) 0..1 ของจอ

  const WalkingVillager({super.key, required this.buildingPositions});

  @override
  State<WalkingVillager> createState() => _WalkingVillagerState();
}

class _WalkingVillagerState extends State<WalkingVillager>
    with TickerProviderStateMixin {
  // ── sprite sheets (ขนาด/จำนวนเฟรมไม่เท่ากัน) ──
  static const _sheetForward = _SheetInfo(
    path: 'assets/games/sprite_sheet/woman_walking.png', // บน->ล่าง, ซ้าย->ขวา
    cols: 3,
    rows: 15,
    sheetW: 480,
    sheetH: 2400,
    validFrames: 43, // เฟรม 43-44 เป็นช่องว่างเปล่า ไม่ใช้
  );
  static const _sheetBackward = _SheetInfo(
    path: 'assets/games/sprite_sheet/woman_walking_2.png', // ขวา->ซ้าย, ล่าง->บน
    cols: 3,
    rows: 12,
    sheetW: 250,
    sheetH: 1000,
    validFrames: 34, // เฟรม 34-35 เป็นช่องว่างเปล่า ไม่ใช้
  );

  // ── ปรับจูนได้ ──
  static const double _displaySize = 64;       // ขนาดตัวละครที่แสดงบนแผนที่
  static const double _obstacleMargin = 0.06;  // ระยะหลบตึก (fraction ของจอ)
  static const int _msPerFractionUnit = 15000; // ความเร็วเดิน: ms ต่อระยะทาง 1.0 (เต็มจอ)
  static const Duration _restDuration = Duration(seconds: 10); // TODO: กลับเป็น 5 นาทีหลังทดสอบเสร็จ
  static const Duration _frameInterval = Duration(milliseconds: 110);

  bool _visible = false;
  Offset _currentPos = Offset.zero;
  _SheetInfo _currentSheet = _sheetForward;
  int _frameIndex = 0;
  bool _reverse = false; // false = ซ้ายบน->ขวาล่าง, true = ขวาล่าง->ซ้ายบน

  Timer? _frameTimer;
  Timer? _restTimer;
  late final AnimationController _moveController;
  List<Offset> _path = [];
  int _segmentIndex = 0;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCycle());
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _restTimer?.cancel();
    _moveController.dispose();
    super.dispose();
  }

  void _startCycle() {
    if (!mounted) return;
    final positions = widget.buildingPositions.values.toList();
    if (positions.length < 2) {
      _restTimer = Timer(const Duration(seconds: 30), _startCycle);
      return;
    }

    Offset topLeft = positions.first;
    Offset bottomRight = positions.first;
    for (final p in positions) {
      if ((p.dx + p.dy) < (topLeft.dx + topLeft.dy)) topLeft = p;
      if ((p.dx + p.dy) > (bottomRight.dx + bottomRight.dy)) bottomRight = p;
    }
    if (topLeft == bottomRight) {
      _restTimer = Timer(const Duration(seconds: 30), _startCycle);
      return;
    }

    final start = _reverse ? bottomRight : topLeft;
    final end = _reverse ? topLeft : bottomRight;
    final obstacles = positions.where((p) => p != start && p != end).toList();

    _path = _buildPath(start, end, obstacles);
    _segmentIndex = 0;
    _currentPos = start;

    setState(() => _visible = true);
    _walkNextSegment();
  }

  List<Offset> _buildPath(Offset start, Offset end, List<Offset> obstacles) {
    final dir = end - start;
    final len = dir.distance;
    if (len == 0) return [start, end];
    final unit = Offset(dir.dx / len, dir.dy / len);
    final normal = Offset(-unit.dy, unit.dx);

    final blockers = <MapEntry<double, Offset>>[];
    for (final ob in obstacles) {
      final toOb = ob - start;
      final t = toOb.dx * unit.dx + toOb.dy * unit.dy;
      if (t <= 0.02 || t >= len - 0.02) continue;
      final perp = toOb.dx * normal.dx + toOb.dy * normal.dy;
      if (perp.abs() < _obstacleMargin) {
        final basePoint = start + unit * t;
        final side = perp >= 0 ? 1 : -1;
        final detour = basePoint + normal * (side * _obstacleMargin * 1.4);
        blockers.add(MapEntry(t, detour));
      }
    }
    blockers.sort((a, b) => a.key.compareTo(b.key));
    return [start, ...blockers.map((e) => e.value), end];
  }

  void _walkNextSegment() {
    if (!mounted || _segmentIndex >= _path.length - 1) {
      _finishCycle();
      return;
    }
    final from = _path[_segmentIndex];
    final to = _path[_segmentIndex + 1];
    final delta = to - from;

    final newSheet = (delta.dx.abs() > delta.dy.abs())
        ? (delta.dx >= 0 ? _sheetForward : _sheetBackward)
        : (delta.dy >= 0 ? _sheetForward : _sheetBackward);

    if (newSheet.path != _currentSheet.path) {
      _frameIndex = 0; // สลับ sheet แล้วรีเซ็ตเฟรม กันเลขเฟรมเกินขอบ sheet ใหม่
    }
    _currentSheet = newSheet;

    final distance = delta.distance;
    final ms = (distance * _msPerFractionUnit).clamp(1200, 20000).toInt();

    _moveController
      ..reset()
      ..duration = Duration(milliseconds: ms);

    _startFrameLoop();

    final animation = Tween<Offset>(begin: from, end: to).animate(_moveController);
    void listener() {
      if (!mounted) return;
      setState(() => _currentPos = animation.value);
    }

    animation.addListener(listener);
    _moveController.forward().whenCompleteOrCancel(() {
      animation.removeListener(listener);
      _frameTimer?.cancel();
      _segmentIndex++;
      _walkNextSegment();
    });
  }

  void _startFrameLoop() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(_frameInterval, (_) {
      if (!mounted) return;
      setState(() => _frameIndex = (_frameIndex + 1) % _currentSheet.totalFrames);
    });
  }

  void _finishCycle() {
    setState(() => _visible = false);
    _reverse = !_reverse;
    _restTimer = Timer(_restDuration, _startCycle);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final size = MediaQuery.of(context).size;
    final sheet = _currentSheet;
    final frameIndex = _frameIndex % sheet.totalFrames; // กันเผื่อ index ค้างจาก sheet อื่น
    final row = frameIndex ~/ sheet.cols;
    final col = frameIndex % sheet.cols;

    return Positioned(
      left: _currentPos.dx * size.width - _displaySize / 2,
      top: _currentPos.dy * size.height - _displaySize,
      child: IgnorePointer(
        child: SizedBox(
          width: _displaySize,
          height: _displaySize,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: sheet.frameW,
              height: sheet.frameH,
              child: ClipRect(
                child: OverflowBox(
                  maxWidth: sheet.sheetW,
                  maxHeight: sheet.sheetH,
                  alignment: Alignment.topLeft,
                  child: Transform.translate(
                    offset: Offset(-col * sheet.frameW, -row * sheet.frameH),
                    child: Image.asset(
                      sheet.path,
                      width: sheet.sheetW,
                      height: sheet.sheetH,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}