class Attempt {
  const Attempt({
    required this.id,
    required this.questionId,
    required this.mode,
    required this.domainId,
    required this.subdomainId,
    required this.answerType,
    this.chosenSingle,
    this.chosenMultiple,
    this.chosenNumeric,
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
  final String answerType; // "single", "multiple", "numeric"
  final int? chosenSingle; // 単一選択の場合（選択肢のインデックス）
  final List<int>? chosenMultiple; // 複数選択の場合（選択肢のインデックスリスト）
  final int? chosenNumeric; // 数値入力の場合
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
      'answerType': answerType,
      if (chosenSingle != null) 'chosenSingle': chosenSingle,
      if (chosenMultiple != null) 'chosenMultiple': chosenMultiple,
      if (chosenNumeric != null) 'chosenNumeric': chosenNumeric,
      'isCorrect': isCorrect,
      'isSkip': isSkip,
      'confidence': confidence,
      'responseTimeMs': responseTimeMs,
      'timeExpired': timeExpired,
      'answeredAt': answeredAt,
      'difficulty': difficulty,
    };
  }

  /// Firestore データから Attempt を復元するファクトリメソッド
  factory Attempt.fromFirestore(String id, Map<String, dynamic> data) {
    return Attempt(
      id: id,
      questionId: data['questionId'] as String,
      mode: data['mode'] as String,
      domainId: data['domainId'] as String,
      subdomainId: data['subdomainId'] as String,
      answerType: data['answerType'] as String,
      chosenSingle: data['chosenSingle'] as int?,
      chosenMultiple: (data['chosenMultiple'] as List<dynamic>?)?.cast<int>(),
      chosenNumeric: data['chosenNumeric'] as int?,
      isCorrect: data['isCorrect'] as bool,
      isSkip: data['isSkip'] as bool,
      confidence: data['confidence'] as String?,
      responseTimeMs: data['responseTimeMs'] as int,
      timeExpired: data['timeExpired'] as bool,
      answeredAt: (data['answeredAt'] as dynamic).toDate(),
      difficulty: (data['difficulty'] as num).toDouble(),
    );
  }

  /// userAnswerからAttemptを作成するファクトリメソッド
  factory Attempt.fromAnswer({
    required String id,
    required String questionId,
    required String mode,
    required String domainId,
    required String subdomainId,
    required String answerType,
    required dynamic userAnswer,
    required bool isCorrect,
    required bool isSkip,
    required String? confidence,
    required int responseTimeMs,
    required bool timeExpired,
    required DateTime answeredAt,
    required double difficulty,
  }) {
    int? chosenSingle;
    List<int>? chosenMultiple;
    int? chosenNumeric;

    if (!isSkip && !timeExpired && userAnswer != null) {
      switch (answerType) {
        case 'single':
          chosenSingle = userAnswer as int;
          break;
        case 'multiple':
          chosenMultiple = (userAnswer as List<int>).toList();
          break;
        case 'numeric':
          chosenNumeric = userAnswer as int;
          break;
      }
    }

    return Attempt(
      id: id,
      questionId: questionId,
      mode: mode,
      domainId: domainId,
      subdomainId: subdomainId,
      answerType: answerType,
      chosenSingle: chosenSingle,
      chosenMultiple: chosenMultiple,
      chosenNumeric: chosenNumeric,
      isCorrect: isCorrect,
      isSkip: isSkip,
      confidence: confidence,
      responseTimeMs: responseTimeMs,
      timeExpired: timeExpired,
      answeredAt: answeredAt,
      difficulty: difficulty,
    );
  }
}