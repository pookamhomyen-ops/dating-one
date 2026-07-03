import 'package:flutter/material.dart';
import 'package:dating_one/soi_mash/game_state.dart';

class ProjectileComponent extends StatelessWidget {
  final Projectile projectile;

  const ProjectileComponent({super.key, required this.projectile});

  @override
  Widget build(BuildContext context) {
    if (projectile.type == ProjectileType.medkit) {
      return Container(
        width: 24, height: 24,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]
        ),
        child: const Icon(Icons.medical_services, color: Colors.red, size: 16),
      );
    }
    
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: projectile.isSpecial ? Colors.purpleAccent : Colors.orange,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
        ]
      ),
    );
  }
}
