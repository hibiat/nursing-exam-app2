class SkillState {
  const SkillState({
    required this.skillId,
    required this.theta,
    required this.nEff,
    required this.lastUpdatedAt,
  });

  final String skillId;
  final double theta;
  final double nEff;
  final DateTime lastUpdatedAt;

  factory SkillState.fromFirestore(String id, Map<String, dynamic> data) {
    final lastUpdatedRaw = data['lastUpdatedAt'];
    final lastUpdatedAt = lastUpdatedRaw is DateTime
        ? lastUpdatedRaw
        : (lastUpdatedRaw as dynamic?)?.toDate() as DateTime?;
    return SkillState(
      skillId: id,
      theta: (data['theta'] as num?)?.toDouble() ?? 0,
      nEff: (data['nEff'] as num?)?.toDouble() ?? 0,
      lastUpdatedAt: lastUpdatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'theta': theta,
      'nEff': nEff,
      'lastUpdatedAt': lastUpdatedAt,
    };
  }

  SkillState copyWith({
    double? theta,
    double? nEff,
    DateTime? lastUpdatedAt,
  }) {
    return SkillState(
      skillId: skillId,
      theta: theta ?? this.theta,
      nEff: nEff ?? this.nEff,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
