import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum AnimalType { fox, monkey, rabbit, raccoon, owl, frog }
enum ProjectileType { normal, medkit }

class Projectile {
  double x, y, vx, vy;
  bool isP1;
  ProjectileType type;
  bool hasSplit;
  bool hasDropped;
  bool isSpecial;

  Projectile({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.isP1,
    this.type = ProjectileType.normal,
    this.hasSplit = false,
    this.hasDropped = false,
    this.isSpecial = false,
  });
}

class Barrier {
  double x, y;
  Barrier(this.x, this.y);
}

class GameState extends ChangeNotifier {
  Size screenSize = Size.zero;
  Timer? _timer;
  
  bool isPlaying = false;
  int currentTurn = 0; // 0 = P1, 1 = P2
  
  int p1Hp = 100;
  int p2Hp = 100;
  
  AnimalType p1Animal = AnimalType.fox;
  AnimalType p2Animal = AnimalType.monkey;
  
  int p1Cooldown = 0;
  int p2Cooldown = 0;
  
  double wind = 0.0;
  bool owlEffectActive = false;
  int throwsLeft = 1;
  
  List<Projectile> projectiles = [];
  List<Barrier> barriers = [];
  
  final double groundY = 120.0;
  final double wallWidth = 20.0;
  final double wallHeight = 220.0;
  
  void initGame(Size size, AnimalType p1, AnimalType p2) {
    screenSize = size;
    p1Animal = p1;
    p2Animal = p2;
    p1Hp = 100;
    p2Hp = 100;
    currentTurn = 0;
    p1Cooldown = 0;
    p2Cooldown = 0;
    projectiles.clear();
    barriers.clear();
    isPlaying = true;
    _randomizeWind();
    _startPhysicsLoop();
    notifyListeners();
  }
  
  void _startPhysicsLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updatePhysics(0.016);
    });
  }
  
  void _randomizeWind() {
    wind = (Random().nextDouble() * 120) - 60;
    owlEffectActive = false;
  }
  
  void fire(Offset start, Offset velocity, bool isHeal, bool isSpecial) {
    if (throwsLeft <= 0 || !isPlaying) return;
    
    AnimalType currentAnimal = currentTurn == 0 ? p1Animal : p2Animal;
    
    if (isSpecial) {
      if (currentTurn == 0) {
        p1Cooldown = 3; // 2 turns cooldown + 1 active
      } else {
        p2Cooldown = 3;
      }
      
      if (currentAnimal == AnimalType.owl) {
        owlEffectActive = true;
      } else if (currentAnimal == AnimalType.monkey) {
        throwsLeft = 2;
      }
    }
    
    projectiles.add(Projectile(
      x: start.dx,
      y: start.dy,
      vx: velocity.dx,
      vy: velocity.dy,
      isP1: currentTurn == 0,
      type: isHeal ? ProjectileType.medkit : ProjectileType.normal,
      isSpecial: isSpecial,
    ));
    
    throwsLeft--;
    notifyListeners();
  }
  
  void _updatePhysics(double dt) {
    if (!isPlaying) return;
    
    bool needsNotify = false;
    List<Projectile> toRemove = [];
    List<Projectile> toAdd = [];
    
    double centerX = screenSize.width / 2;
    double wallX = centerX - wallWidth / 2;
    double wallTopY = screenSize.height - groundY - wallHeight;
    
    for (var p in projectiles) {
      needsNotify = true;
      
      p.vy += 800 * dt; // Gravity
      
      if (!owlEffectActive) {
        p.vx += wind * dt;
      }
      
      double nextX = p.x + p.vx * dt;
      double nextY = p.y + p.vy * dt;
      
      AnimalType ownerAnimal = p.isP1 ? p1Animal : p2Animal;
      
      // Screen Edge Collision (ซ้าย-ขวาของจอ ทำตัวเหมือนกำแพง)
      const double edgeRadius = 8.0;
      if (nextX < edgeRadius) {
        p.vx = -p.vx * 0.7;
        nextX = edgeRadius;
      } else if (nextX > screenSize.width - edgeRadius) {
        p.vx = -p.vx * 0.7;
        nextX = screenSize.width - edgeRadius;
      }
      
      // Fox Skill
      if (p.isSpecial && ownerAnimal == AnimalType.fox && !p.hasSplit) {
        if ((p.isP1 && nextX > centerX) || (!p.isP1 && nextX < centerX)) {
          p.hasSplit = true;
          toAdd.add(Projectile(
            x: nextX, y: nextY, vx: p.vx, vy: p.vy - 150, 
            isP1: p.isP1, isSpecial: true, hasSplit: true
          ));
        }
      }
      
      // Frog Skill
      if (p.isSpecial && ownerAnimal == AnimalType.frog && !p.hasDropped) {
         if ((p.isP1 && nextX > centerX) || (!p.isP1 && nextX < centerX)) {
           p.hasDropped = true;
           p.vx = 0;
           p.vy = 800; // Drop instantly
         }
      }
      
      // Wall Collision
      if (nextX > wallX && nextX < wallX + wallWidth && nextY > wallTopY) {
         if (p.isSpecial && ownerAnimal == AnimalType.raccoon) {
           barriers.add(Barrier(nextX, nextY));
           toRemove.add(p);
           continue;
         } else if (p.isSpecial && ownerAnimal == AnimalType.rabbit) {
           p.vx = -p.vx * 2;
           nextX = p.x + p.vx * dt;
         } else {
           p.vx = -p.vx * 0.5;
           nextX = p.x + p.vx * dt;
         }
      }
      
      // Barrier Collision
      for (var b in barriers) {
        if ((nextX - b.x).abs() < 20 && (nextY - b.y).abs() < 20) {
          p.vx = -p.vx * 0.5;
          nextX = p.x + p.vx * dt;
          break;
        }
      }
      
      // Ground Collision
      if (nextY > screenSize.height - groundY) {
        if (p.type != ProjectileType.medkit) {
          // AoE Damage
          if (p.isP1 && nextX > centerX) p2Hp -= 10;
          if (!p.isP1 && nextX < centerX) p1Hp -= 10;
        }
        toRemove.add(p);
        continue;
      }
      
      // Player Collision
      double p1x = 80.0;
      double p2x = screenSize.width - 80.0;
      double playerY = screenSize.height - groundY - 30.0;
      
      if (p.isP1 && (nextX - p2x).abs() < 40 && (nextY - playerY).abs() < 40) {
        if (p.type == ProjectileType.medkit) {
           p1Hp = min(100, p1Hp + 20); // Heals thrower
        } else {
           p2Hp -= 20;
        }
        toRemove.add(p);
        continue;
      }
      if (!p.isP1 && (nextX - p1x).abs() < 40 && (nextY - playerY).abs() < 40) {
        if (p.type == ProjectileType.medkit) {
           p2Hp = min(100, p2Hp + 20);
        } else {
           p1Hp -= 20;
        }
        toRemove.add(p);
        continue;
      }
      
      p.x = nextX;
      p.y = nextY;
    }
    
    projectiles.removeWhere((p) => toRemove.contains(p));
    projectiles.addAll(toAdd);
    
    if (p1Hp <= 0 || p2Hp <= 0) {
      isPlaying = false;
      needsNotify = true;
    }
    
    if (throwsLeft == 0 && projectiles.isEmpty && isPlaying) {
      _nextTurn();
      needsNotify = true;
    }
    
    if (needsNotify) notifyListeners();
  }

  void _nextTurn() {
    currentTurn = currentTurn == 0 ? 1 : 0;
    throwsLeft = 1;
    if (currentTurn == 0 && p1Cooldown > 0) p1Cooldown--;
    if (currentTurn == 1 && p2Cooldown > 0) p2Cooldown--;
    // เปลี่ยนลมทุกๆ 2 ตา (ตอนวนกลับมาเป็น Player 1) ลมจะไม่เปลี่ยนทุกตา
    if (currentTurn == 0) {
      _randomizeWind();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
