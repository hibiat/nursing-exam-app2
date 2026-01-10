class SkillState {
  const SkillState({
    required this.subdomainId,
    required this.theta,
    required this.nEff,
    required this.lastUpdatedAt,
  });

  final String subdomainId;
  final double theta;
  final double nEff;
  final DateTime lastUpdatedAt;

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
      subdomainId: subdomainId,
      theta: theta ?? this.theta,
      nEff: nEff ?? this.nEff,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
