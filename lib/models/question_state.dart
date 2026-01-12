class QuestionState {
  const QuestionState({
    required this.questionId,
    required this.mode,
    required this.domainId,
    required this.dueAt,
    required this.stability,
    required this.lapses,
    required this.lastSeenAt,
  });

  final String questionId;
  final String mode;
  final String domainId;
  final DateTime dueAt;
  final double stability;
  final int lapses;
  final DateTime lastSeenAt;

  factory QuestionState.fromFirestore(String id, Map<String, dynamic> data) {
    final dueRaw = data['dueAt'];
    final lastSeenRaw = data['lastSeenAt'];
    final dueAt =
        dueRaw is DateTime ? dueRaw : (dueRaw as dynamic?)?.toDate() as DateTime?;
    final lastSeenAt = lastSeenRaw is DateTime
        ? lastSeenRaw
        : (lastSeenRaw as dynamic?)?.toDate() as DateTime?;
    return QuestionState(
      questionId: id,
      mode: (data['mode'] as String?) ?? 'general',
      domainId: (data['domainId'] as String?) ?? '',
      dueAt: dueAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      stability: (data['stability'] as num?)?.toDouble() ?? 1,
      lapses: (data['lapses'] as num?)?.toInt() ?? 0,
      lastSeenAt: lastSeenAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dueAt': dueAt,
      'stability': stability,
      'lapses': lapses,
      'lastSeenAt': lastSeenAt,
      'mode': mode,
      'domainId': domainId,
    };
  }
}
