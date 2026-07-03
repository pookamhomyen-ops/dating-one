import 'package:flutter/material.dart';
import 'package:dating_one/soi_mash/game_state.dart';

class CharacterComponent extends StatelessWidget {
  final AnimalType animalType;
  final int hp;
  final bool isFlipped;
  final bool isTurn;

  const CharacterComponent({
    super.key,
    required this.animalType,
    required this.hp,
    this.isFlipped = false,
    this.isTurn = false,
  });

  IconData _getIcon() {
    switch (animalType) {
      case AnimalType.fox: return Icons.pets;
      case AnimalType.monkey: return Icons.face;
      case AnimalType.rabbit: return Icons.cruelty_free;
      case AnimalType.raccoon: return Icons.catching_pokemon;
      case AnimalType.owl: return Icons.visibility;
      case AnimalType.frog: return Icons.bug_report;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Turn indicator
        if (isTurn) const Icon(Icons.arrow_drop_down, color: Colors.yellow, size: 32),
        if (!isTurn) const SizedBox(height: 32),
        
        // HP Bar
        Container(
          width: 60,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.red[900],
            border: Border.all(color: Colors.black, width: 1)
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (hp / 100).clamp(0.0, 1.0),
            child: Container(color: hp > 40 ? Colors.greenAccent : Colors.redAccent),
          ),
        ),
        const SizedBox(height: 4),
        
        // Character Icon
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(isFlipped ? 3.14159 : 0),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isTurn ? Colors.yellow : Colors.black, width: isTurn ? 3 : 2),
              boxShadow: [
                if (isTurn) const BoxShadow(color: Colors.yellowAccent, blurRadius: 10)
              ]
            ),
            child: Icon(_getIcon(), size: 36, color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }
}
