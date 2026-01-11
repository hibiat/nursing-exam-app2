class QuestionState {
  const QuestionState({
    required this.questionId,
    required this.dueAt,
    required this.stability,
    required this.lapses,
    required this.lastSeenAt,
  });

  final String questionId;
  final DateTime dueAt;
  final double stability;
  final int lapses;
  final DateTime lastSeenAt;

  Map<String, dynamic> toFirestore() {
    return {
      'dueAt': dueAt,
      'stability': stability,
      'lapses': lapses,
      'lastSeenAt': lastSeenAt,
    };
  }
}
