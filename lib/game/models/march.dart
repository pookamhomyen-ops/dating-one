class March {
  final String id;
  final String settlementId;
  final String marchType;
  final String? targetNodeId;
  final String? targetSettlementId;
  final Map<String, int> troopsSent;
  final DateTime departAt;
  final DateTime arriveAt;
  final String status;
  final Map<String, int> loot;
  final DateTime createdAt;

  const March({
    required this.id,
    required this.settlementId,
    required this.marchType,
    this.targetNodeId,
    this.targetSettlementId,
    required this.troopsSent,
    required this.departAt,
    required this.arriveAt,
    required this.status,
    required this.loot,
    required this.createdAt,
  });

  factory March.fromJson(Map<String, dynamic> json) {
    return March(
      id: json['id'],
      settlementId: json['settlement_id'],
      marchType: json['march_type'],
      targetNodeId: json['target_node_id'],
      targetSettlementId: json['target_settlement_id'],
      troopsSent: Map<String, int>.from(json['troops_sent'] ?? {}),
      departAt: DateTime.parse(json['depart_at']),
      arriveAt: DateTime.parse(json['arrive_at']),
      status: json['status'],
      loot: Map<String, int>.from(json['loot'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Duration get timeRemaining {
    final remaining = arriveAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get hasArrived => DateTime.now().isAfter(arriveAt);

  String get statusDisplay {
    switch (marchType) {
      case 'attack':    return 'กำลังเดินทัพ';
      case 'return':    return 'กำลังเดินทางกลับ';
      case 'reinforce': return 'กำลังส่งกองหนุน';
      default:          return status;
    }
  }

  // รวม attack power ของกองทัพที่ส่งไป
  int get totalAttackPower {
    const power = {
      'swordsman': 10,
      'archer':    12,
      'spearman':  8,
      'cavalry':   18,
      'elephant':  35,
    };
    int total = 0;
    troopsSent.forEach((type, count) {
      total += (power[type] ?? 10) * count;
    });
    return total;
  }
}