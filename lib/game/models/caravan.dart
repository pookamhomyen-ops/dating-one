class Caravan {
  final String id;
  final String fromSettlementId;
  final String toSettlementId;
  final Map<String, int> payload;
  final String? message;
  final DateTime departAt;
  final DateTime arriveAt;
  final String status;
  final DateTime createdAt;

  const Caravan({
    required this.id,
    required this.fromSettlementId,
    required this.toSettlementId,
    required this.payload,
    this.message,
    required this.departAt,
    required this.arriveAt,
    required this.status,
    required this.createdAt,
  });

  factory Caravan.fromJson(Map<String, dynamic> json) {
    return Caravan(
      id: json['id'],
      fromSettlementId: json['from_settlement_id'],
      toSettlementId: json['to_settlement_id'],
      payload: Map<String, int>.from(json['payload'] ?? {}),
      message: json['message'],
      departAt: DateTime.parse(json['depart_at']),
      arriveAt: DateTime.parse(json['arrive_at']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get hasArrived => DateTime.now().isAfter(arriveAt);

  Duration get timeRemaining {
    final remaining = arriveAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}