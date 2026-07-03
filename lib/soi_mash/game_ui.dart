import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dating_one/soi_mash/game_state.dart';
import 'package:dating_one/soi_mash/components/wall.dart';
import 'package:dating_one/soi_mash/components/character.dart';
import 'package:dating_one/soi_mash/components/projectile.dart';

class GameUI extends StatefulWidget {
  const GameUI({super.key});

  @override
  State<GameUI> createState() => _GameUIState();
}

class _GameUIState extends State<GameUI> {
  final GameState state = GameState();
  Offset? dragStart;
  Offset? dragCurrent;
  
  bool isHealSelected = false;
  bool isSpecialSelected = false;

  final List<Color> bgColors = [
    Colors.deepPurple[900]!,
    Colors.indigo[900]!,
    Colors.blueGrey[900]!,
    Colors.brown[800]!,
  ];
  late Color currentBg;

  @override
  void initState() {
    super.initState();
    currentBg = bgColors[Random().nextInt(bgColors.length)];
    // Delay initialization until layout completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showCharacterSelectionDialog();
      }
    });
  }

  void _showCharacterSelectionDialog() {
    AnimalType p1 = AnimalType.fox;
    AnimalType p2 = AnimalType.monkey;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("เลือกตัวละคร (Soi Smash)"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Player 1 (ซ้าย)"),
                  DropdownButton<AnimalType>(
                    value: p1,
                    onChanged: (v) => setDialogState(() => p1 = v!),
                    items: AnimalType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text("Player 2 (ขวา)"),
                  DropdownButton<AnimalType>(
                    value: p2,
                    onChanged: (v) => setDialogState(() => p2 = v!),
                    items: AnimalType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
                  ),
                ],
              );
            }
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  currentBg = bgColors[Random().nextInt(bgColors.length)];
                });
                state.initGame(MediaQuery.of(context).size, p1, p2);
              },
              child: const Text("เริ่มเกม"),
            )
          ],
        );
      }
    );
  }

  void onPanStart(DragStartDetails details) {
    if (!state.isPlaying) return;
    double centerX = state.screenSize.width / 2;
    if (state.currentTurn == 0 && details.localPosition.dx > centerX) return;
    if (state.currentTurn == 1 && details.localPosition.dx < centerX) return;
    
    setState(() {
      dragStart = details.localPosition;
      dragCurrent = details.localPosition;
    });
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (dragStart != null) {
      setState(() {
        dragCurrent = details.localPosition;
      });
    }
  }

  void onPanEnd(DragEndDetails details) {
    if (dragStart != null && dragCurrent != null) {
      Offset dragVector = dragStart! - dragCurrent!;
      Offset velocity = dragVector * 5.0; // Multiplier for speed
       
      double startX = state.currentTurn == 0 ? 80.0 : state.screenSize.width - 80.0;
      double startY = state.screenSize.height - state.groundY - 30.0;
       
      state.fire(Offset(startX, startY), velocity, isHealSelected, isSpecialSelected);
       
      isHealSelected = false;
      isSpecialSelected = false;
    }
    setState(() {
      dragStart = null;
      dragCurrent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: currentBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (state.screenSize.width == 0) {
            state.screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          }
          
          return ListenableBuilder(
            listenable: state,
            builder: (context, child) {
              
              if (!state.isPlaying && state.p1Hp != 100 && state.p2Hp != 100) {
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => AlertDialog(
                        title: const Text("จบเกม!"),
                        content: Text(state.p1Hp <= 0 ? "Player 2 ชนะ!" : "Player 1 ชนะ!"),
                        actions: [
                          TextButton(onPressed: () {
                            Navigator.pop(context);
                            _showCharacterSelectionDialog();
                          }, child: const Text("เล่นใหม่"))
                        ],
                      )
                    );
                 });
              }

              return Stack(
                children: [
                  // City background buildings (Simplified)
                  Positioned(
                    bottom: state.groundY,
                    left: 0, right: 0,
                    height: 100,
                    child: Container(
                      color: Colors.black26,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(10, (i) => Container(
                          width: 30, height: 50 + Random(i).nextDouble() * 50,
                          color: Colors.black45,
                        )),
                      ),
                    ),
                  ),
                  
                  // Ground
                  Positioned(
                    bottom: 0, left: 0, right: 0, height: state.groundY,
                    child: Container(color: Colors.grey[800]),
                  ),
                  
                  // Drag Area
                  Positioned.fill(
                    child: GestureDetector(
                      onPanStart: onPanStart,
                      onPanUpdate: onPanUpdate,
                      onPanEnd: onPanEnd,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  
                  // Trajectory line preview (simple)
                  if (dragStart != null && dragCurrent != null)
                    CustomPaint(
                       painter: TrajectoryPainter(
                         dragStart!, dragCurrent!,
                         state.currentTurn == 0 ? 80.0 : state.screenSize.width - 80.0,
                         state.screenSize.height - state.groundY - 30.0,
                       ),
                       size: Size.infinite,
                    ),

                  // Wall
                  Positioned(
                    bottom: state.groundY,
                    left: state.screenSize.width / 2 - state.wallWidth / 2,
                    child: WallComponent(width: state.wallWidth, height: state.wallHeight),
                  ),
                  
                  // Player 1
                  Positioned(
                    bottom: state.groundY,
                    left: 50,
                    child: CharacterComponent(animalType: state.p1Animal, hp: state.p1Hp, isTurn: state.currentTurn == 0),
                  ),
                  
                  // Player 2
                  Positioned(
                    bottom: state.groundY,
                    right: 50,
                    child: CharacterComponent(animalType: state.p2Animal, hp: state.p2Hp, isFlipped: true, isTurn: state.currentTurn == 1),
                  ),

                  // Barriers (Raccoon)
                  ...state.barriers.map((b) => Positioned(
                    left: b.x - 10, top: b.y - 10,
                    child: Container(width: 20, height: 20, color: Colors.brown),
                  )),

                  // Projectiles
                  ...state.projectiles.map((p) => Positioned(
                    left: p.x - 8, top: p.y - 8,
                    child: ProjectileComponent(projectile: p),
                  )),

                  // UI Overlay (Top)
                  Positioned(
                    top: 40, left: 20, right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("P1 HP: ${state.p1Hp}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Column(
                          children: [
                            Text("Turn: Player ${state.currentTurn + 1}", style: const TextStyle(color: Colors.yellow, fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            _WindIndicator(
                              wind: state.owlEffectActive ? 0 : state.wind,
                            ),
                          ],
                        ),
                        Text("P2 HP: ${state.p2Hp}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // Skills UI
                  Positioned(
                    bottom: 20, left: 20, right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSkillPanel(0),
                        _buildSkillPanel(1),
                      ],
                    ),
                  )
                ],
              );
            }
          );
        }
      )
    );
  }

  Widget _buildSkillPanel(int playerIndex) {
    bool isMyTurn = state.currentTurn == playerIndex;
    int cooldown = playerIndex == 0 ? state.p1Cooldown : state.p2Cooldown;
    
    return Opacity(
      opacity: isMyTurn ? 1.0 : 0.4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isHealSelected && isMyTurn ? Colors.green : Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onPressed: isMyTurn ? () => setState(() { isHealSelected = true; isSpecialSelected = false; }) : null,
            child: const Text("Heal (20%)", style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSpecialSelected && isMyTurn ? Colors.purpleAccent : Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onPressed: (isMyTurn && cooldown == 0) ? () => setState(() { isSpecialSelected = true; isHealSelected = false; }) : null,
            child: Text(cooldown > 0 ? "Skill ($cooldown)" : "Skill", style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _WindIndicator extends StatelessWidget {
  final double wind;
  const _WindIndicator({required this.wind});

  static const double _maxWind = 60.0;

  @override
  Widget build(BuildContext context) {
    final double clamped = wind.clamp(-_maxWind, _maxWind);
    final double strength = (clamped.abs() / _maxWind).clamp(0.0, 1.0);

    // ลมบวก = พัดไปทางขวา -> ลูกศรชี้ขวา (มุมบวกตามแกน atan2 คือหมุนตามเข็ม)
    // ใช้ช่วงมุม -55deg (ชี้ซ้ายเฉียงขึ้น) ถึง +55deg (ชี้ขวาเฉียงขึ้น) จากแนวตั้งฉาก (ชี้ขึ้น = ลมสงบ)
    final double angle = (clamped / _maxWind) * (pi * 0.55);

    final Color arrowColor = Color.lerp(
      Colors.lightBlueAccent.withValues(alpha: 0.55),
      Colors.cyanAccent,
      strength,
    )!;

    final double size = 26 + strength * 16; // 26 ~ 42

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: arrowColor.withValues(alpha: 0.45 * strength + 0.1),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            turns: angle / (2 * pi),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: size,
              height: size,
              child: Icon(
                Icons.navigation_rounded,
                size: size,
                color: arrowColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          wind.abs() < 3 ? "นิ่ง" : clamped > 0 ? "พัดขวา" : "พัดซ้าย",
          style: TextStyle(
            color: arrowColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class TrajectoryPainter extends CustomPainter {
  final Offset dragStart, dragCurrent;
  final double startX, startY;
  
  TrajectoryPainter(this.dragStart, this.dragCurrent, this.startX, this.startY);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white54..strokeWidth = 2..style = PaintingStyle.stroke;
    Offset dragVector = dragStart - dragCurrent;
    canvas.drawLine(Offset(startX, startY), Offset(startX + dragVector.dx, startY + dragVector.dy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
