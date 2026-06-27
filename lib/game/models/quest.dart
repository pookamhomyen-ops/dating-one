class Quest {
  final String id;
  final String questType;
  final String title;
  final String description;
  final String requirementType;
  final int requirementAmount;
  final int rewardWood;
  final int rewardIron;
  final int rewardRice;
  final int rewardLiquor;
  final bool isActive;

  const Quest({
    required this.id,
    required this.questType,
    required this.title,
    required this.description,
    required this.requirementType,
    required this.requirementAmount,
    required this.rewardWood,
    required this.rewardIron,
    required this.rewardRice,
    required this.rewardLiquor,
    required this.isActive,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      questType: json['quest_type'],
      title: json['title'],
      description: json['description'],
      requirementType: json['requirement_type'],
      requirementAmount: json['requirement_amount'],
      rewardWood: json['reward_wood'] ?? 0,
      rewardIron: json['reward_iron'] ?? 0,
      rewardRice: json['reward_rice'] ?? 0,
      rewardLiquor: json['reward_liquor'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  String get typeEmoji => questType == 'daily' ? '📅' : '📆';
  String get typeLabel => questType == 'daily' ? 'รายวัน' : 'รายสัปดาห์';
}

class QuestProgress {
  final String id;
  final String settlementId;
  final String questId;
  final int currentAmount;
  final bool isCompleted;
  final bool isClaimed;
  final DateTime lastResetAt;

  const QuestProgress({
    required this.id,
    required this.settlementId,
    required this.questId,
    required this.currentAmount,
    required this.isCompleted,
    required this.isClaimed,
    required this.lastResetAt,
  });

  factory QuestProgress.fromJson(Map<String, dynamic> json) {
    return QuestProgress(
      id: json['id'],
      settlementId: json['settlement_id'],
      questId: json['quest_id'],
      currentAmount: json['current_amount'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      isClaimed: json['is_claimed'] ?? false,
      lastResetAt: DateTime.parse(json['last_reset_at']),
    );
  }
}

class QuestWithProgress {
  final Quest quest;
  final QuestProgress? progress;

  const QuestWithProgress({required this.quest, this.progress});

  int get currentAmount => progress?.currentAmount ?? 0;
  bool get isCompleted => progress?.isCompleted ?? false;
  bool get isClaimed => progress?.isClaimed ?? false;
  bool get isReadyToClaim => isCompleted && !isClaimed;

  double get progressFraction =>
      (currentAmount / quest.requirementAmount).clamp(0.0, 1.0);
}
