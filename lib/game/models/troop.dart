class Troop {
  final String id;
  final String settlementId;
  final String troopType;
  final int count;
  final int trainingCount;
  final DateTime? trainingFinishAt;

  const Troop({
    required this.id,
    required this.settlementId,
    required this.troopType,
    required this.count,
    required this.trainingCount,
    this.trainingFinishAt,
  });

  factory Troop.fromJson(Map<String, dynamic> json) {
    return Troop(
      id: json['id'],
      settlementId: json['settlement_id'],
      troopType: json['troop_type'],
      count: json['count'],
      trainingCount: json['training_count'],
      trainingFinishAt: json['training_finish_at'] != null
          ? DateTime.parse(json['training_finish_at'])
          : null,
    );
  }

  String get displayName {
    const names = {
      'swordsman': 'พลดาบ',
      'archer':    'พลธนู',
      'spearman':  'พลทวน',
      'cavalry':   'ทหารม้า',
      'elephant':  'ช้างศึก',
    };
    return names[troopType] ?? troopType;
  }

  String get emoji {
    const emojis = {
      'swordsman': '🗡️',
      'archer':    '🏹',
      'spearman':  '🪖',
      'cavalry':   '🐴',
      'elephant':  '🐘',
    };
    return emojis[troopType] ?? '⚔️';
  }

  // ต้นทุนต่อคน
  Map<String, int> get costPerUnit {
    const costs = {
      'swordsman': {'wood': 5,  'iron': 3},
      'archer':    {'wood': 8,  'iron': 2},
      'spearman':  {'wood': 4,  'iron': 6},
      'cavalry':   {'wood': 10, 'iron': 10},
      'elephant':  {'wood': 20, 'iron': 20},
    };
    return Map<String, int>.from(costs[troopType] ?? {'wood': 5, 'iron': 5});
  }

  // attack power ต่อหน่วย
  int get attackPower {
    const power = {
      'swordsman': 10,
      'archer':    12,
      'spearman':  8,
      'cavalry':   18,
      'elephant':  35,
    };
    return power[troopType] ?? 10;
  }

  // defense power ต่อหน่วย
  int get defensePower {
    const power = {
      'swordsman': 10,
      'archer':    6,
      'spearman':  15,
      'cavalry':   14,
      'elephant':  30,
    };
    return power[troopType] ?? 10;
  }

  // เวลาฝึก (วินาที) ต่อ 10 คน
  int get trainingSeconds {
    const seconds = {
      'swordsman': 300,   // 5 นาที
      'archer':    300,
      'spearman':  300,
      'cavalry':   600,   // 10 นาที
      'elephant':  900,   // 15 นาที
    };
    return seconds[troopType] ?? 300;
  }

  bool get isTraining =>
      trainingCount > 0 && trainingFinishAt != null;

  Duration? get trainingTimeRemaining {
    if (!isTraining || trainingFinishAt == null) return null;
    final remaining = trainingFinishAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}