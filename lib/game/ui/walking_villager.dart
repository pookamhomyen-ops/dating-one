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
/// หลบตึกตามขนาด grid จริง (3 cols x 2 rows, anchor = กลางล่าง), หยุดที่ขอบอาคารก่อนหาย
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

  // ── ระยะ/ขนาดอาคารจริง (อิงจาก arrange_buildings_view.dart) ──
  // grid 20x20, มุม diamond: vTop(0.503,0.066) vRight(0.992,0.444) vBottom(0.519,0.860) vLeft(0.026,0.324)
  // อาคาร 1 หลัง ยึด 3 cols x 2 rows, anchor = กลางล่างของพื้นที่นั้น
  static const double _gridCellW = 0.0483; // (vRight.dx-vLeft.dx)/20 โดยประมาณ
  static const double _gridCellH = 0.0397; // (vBottom.dy-vTop.dy)/20 โดยประมาณ
  static const double _buildingHalfWidth = (3 * _gridCellW) / 2; // ~0.0725
  static const double _buildingHeight = 2 * _gridCellH; // ~0.0794
  static const double _obstacleCenterYOffset = _buildingHeight / 2; // เลื่อนจุดเช็คชนขึ้นจาก anchor (bottom) ไปกลางอาคารจริง
  static const double _obstacleRadius = 0.11; // รัศมีครอบคลุมอาคาร (คำนวณจาก halfWidth/height) + กันชน

  // ── ปรับจูนได้ ──
  static const double _displaySize = 44;       // ขนาดตัวละครที่แสดงบนแผนที่ (ลดจาก 64)
  static const double _arrivalOffset = 0.055;  // ระยะหยุด/โผล่ ก่อนถึงศูนย์กลางอาคารต้นทาง-ปลายทาง
  static const int _msPerFractionUnit = 35000; // ความเร็วเดิน: ms ต่อระยะทาง 1.0 (เต็มจอ)
  static const Duration _restDuration = Duration(seconds: 10); // TODO: กลับเป็น 5 นาทีหลังทดสอบเสร็จ
  static const Duration _gaitCycleDuration = Duration(milliseconds: 1400); // เวลาเดินครบ 1 รอบก้าว เท่ากันทั้ง 2 sheet

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

    final rawPath = _buildPath(start, end, obstacles);

    // ปรับจุดเริ่ม/จบให้ "โผล่จากขอบอาคาร" และ "หยุดที่ขอบอาคาร" แทนการอยู่กลางอาคารเป๊ะๆ
    if (rawPath.length >= 2) {
      rawPath[0] = _offsetFromCenter(rawPath.first, rawPath[1], _arrivalOffset);
      rawPath[rawPath.length - 1] = _offsetFromCenter(
          rawPath.last, rawPath[rawPath.length - 2], _arrivalOffset);
    }

    _path = rawPath;
    _segmentIndex = 0;
    _currentPos = _path.first;

    setState(() => _visible = true);
    _walkNextSegment();
  }

  /// เลื่อนจุด center ออกไปทาง towards เป็นระยะ dist (ใช้ทำให้ตัวละครโผล่/หยุดที่ขอบอาคาร)
  Offset _offsetFromCenter(Offset center, Offset towards, double dist) {
    final delta = towards - center;
    final len = delta.distance;
    if (len <= dist || len == 0) return center;
    final unit = Offset(delta.dx / len, delta.dy / len);
    return center + unit * dist;
  }

  /// แทรก waypoint อ้อมตึกที่ขวางเส้นทางตรงระหว่าง start -> end
  /// ใช้จุดศูนย์กลางอาคารจริง (เลื่อนขึ้นจาก anchor) + รัศมีตามขนาดอาคารจริง (3x2 grid)
  List<Offset> _buildPath(Offset start, Offset end, List<Offset> obstacles) {
    final dir = end - start;
    final len = dir.distance;
    if (len == 0) return [start, end];
    final unit = Offset(dir.dx / len, dir.dy / len);
    final normal = Offset(-unit.dy, unit.dx);

    final blockers = <MapEntry<double, Offset>>[];
    for (final ob in obstacles) {
      final obCenter = Offset(ob.dx, ob.dy - _obstacleCenterYOffset);
      final toOb = obCenter - start;
      final t = toOb.dx * unit.dx + toOb.dy * unit.dy;
      if (t <= 0.02 || t >= len - 0.02) continue;
      final perp = toOb.dx * normal.dx + toOb.dy * normal.dy;
      if (perp.abs() < _obstacleRadius) {
        final basePoint = start + unit * t;
        final side = perp >= 0 ? 1 : -1;
        final detour = basePoint + normal * (side * _obstacleRadius * 1.4);
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

  /// interval ต่อเฟรม คำนวณจากจำนวนเฟรมของ sheet ปัจจุบัน หาร _gaitCycleDuration
  /// ทำให้ทั้ง 2 sheet เดินครบ 1 รอบก้าวในเวลาเท่ากันเสมอ (ขาไป-ขากลับจังหวะเท่ากัน)
  void _startFrameLoop() {
    _frameTimer?.cancel();
    final interval = Duration(
      milliseconds:
          (_gaitCycleDuration.inMilliseconds / _currentSheet.totalFrames).round(),
    );
    _frameTimer = Timer.periodic(interval, (_) {
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