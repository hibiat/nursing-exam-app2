class StreakState {
  const StreakState({
    required this.currentStreak,
    required this.lastStudyDate,
    required this.lastUnitCompletedAt,
  });

  final int currentStreak;
  final DateTime? lastStudyDate;
  final DateTime? lastUnitCompletedAt;

  factory StreakState.fromFirestore(Map<String, dynamic> data) {
    final lastStudyRaw = data['lastStudyDate'];
    final lastUnitRaw = data['lastUnitCompletedAt'];
    final lastStudyDate = lastStudyRaw is DateTime
        ? lastStudyRaw
        : (lastStudyRaw as dynamic?)?.toDate() as DateTime?;
    final lastUnitCompletedAt = lastUnitRaw is DateTime
        ? lastUnitRaw
        : (lastUnitRaw as dynamic?)?.toDate() as DateTime?;
    return StreakState(
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      lastStudyDate: lastStudyDate,
      lastUnitCompletedAt: lastUnitCompletedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'currentStreak': currentStreak,
      'lastStudyDate': lastStudyDate,
      'lastUnitCompletedAt': lastUnitCompletedAt,
    };
  }
}
