class Attempt {
  const Attempt({
    required this.id,
    required this.questionId,
    required this.mode,
    required this.domainId,
    required this.subdomainId,
    required this.chosen,
    required this.isCorrect,
    required this.isSkip,
    required this.confidence,
    required this.responseTimeMs,
    required this.timeExpired,
    required this.answeredAt,
    required this.difficulty,
  });

  final String id;
  final String questionId;
  final String mode;
  final String domainId;
  final String subdomainId;
  final String chosen;
  final bool isCorrect;
  final bool isSkip;
  final String? confidence;
  final int responseTimeMs;
  final bool timeExpired;
  final DateTime answeredAt;
  final double difficulty;

  Map<String, dynamic> toFirestore() {
    return {
      'questionId': questionId,
      'mode': mode,
      'domainId': domainId,
      'subdomainId': subdomainId,
      'chosen': chosen,
      'isCorrect': isCorrect,
      'isSkip': isSkip,
      'confidence': confidence,
      'responseTimeMs': responseTimeMs,
      'timeExpired': timeExpired,
      'answeredAt': answeredAt,
      'difficulty': difficulty,
    };
  }
}
