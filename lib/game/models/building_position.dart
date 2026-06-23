class BuildingPosition {
  final String id;
  final String settlementId;
  final String buildingId;
  final int posX;
  final int posY;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BuildingPosition({
    required this.id,
    required this.settlementId,
    required this.buildingId,
    required this.posX,
    required this.posY,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BuildingPosition.fromJson(Map<String, dynamic> json) {
    return BuildingPosition(
      id: json['id'],
      settlementId: json['settlement_id'],
      buildingId: json['building_id'],
      posX: json['pos_x'],
      posY: json['pos_y'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'settlement_id': settlementId,
    'building_id': buildingId,
    'pos_x': posX,
    'pos_y': posY,
  };
}