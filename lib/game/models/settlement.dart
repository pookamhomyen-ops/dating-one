class Settlement {
  final String id;
  final String playerId;
  final String name;
  final int mapX;
  final int mapY;

  // ทรัพยากร
  final int wood;
  final int iron;
  final int rice;
  final int liquor;

  // ประชาชน
  final int population;
  final int maxPopulation;

  // happiness 0-100
  final int happiness;
  final DateTime happinessUpdatedAt;

  final DateTime createdAt;

  const Settlement({
    required this.id,
    required this.playerId,
    required this.name,
    required this.mapX,
    required this.mapY,
    required this.wood,
    required this.iron,
    required this.rice,
    required this.liquor,
    required this.population,
    required this.maxPopulation,
    required this.happiness,
    required this.happinessUpdatedAt,
    required this.createdAt,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'],
      playerId: json['player_id'],
      name: json['name'],
      mapX: json['map_x'],
      mapY: json['map_y'],
      wood: json['wood'],
      iron: json['iron'],
      rice: json['rice'],
      liquor: json['liquor'],
      population: json['population'],
      maxPopulation: json['max_population'],
      happiness: json['happiness'],
      happinessUpdatedAt: DateTime.parse(json['happiness_updated_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // happiness status สำหรับแสดง UI
  String get happinessEmoji {
    if (happiness >= 70) return '😊';
    if (happiness >= 40) return '😐';
    if (happiness >= 20) return '😠';
    return '💀';
  }

  // ทหารสูงสุดที่มีได้
  int get maxTroops => (population * 1.5).floor();

  Settlement copyWith({
    int? wood, int? iron, int? rice, int? liquor,
    int? population, int? maxPopulation, int? happiness,
  }) {
    return Settlement(
      id: id, playerId: playerId, name: name,
      mapX: mapX, mapY: mapY,
      wood: wood ?? this.wood,
      iron: iron ?? this.iron,
      rice: rice ?? this.rice,
      liquor: liquor ?? this.liquor,
      population: population ?? this.population,
      maxPopulation: maxPopulation ?? this.maxPopulation,
      happiness: happiness ?? this.happiness,
      happinessUpdatedAt: happinessUpdatedAt,
      createdAt: createdAt,
    );
  }
}