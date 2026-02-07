/// 選択肢の構造
class QuestionChoice {
  const QuestionChoice({
    required this.index,
    required this.text,
  });

  final int index;
  final String text;

  factory QuestionChoice.fromJson(Map<String, dynamic> json) {
    return QuestionChoice(
      index: json['index'] as int,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'text': text,
    };
  }
}

/// 解答の構造
class QuestionAnswer {
  const QuestionAnswer({
    required this.type,
    this.value,
    this.values,
    this.count,
    this.unit,
    this.digits,
    this.decimalRule,
  });

  final String type; // "single", "multiple", "numeric"
  final int? value; // 単一選択・数値の場合
  final List<int>? values; // 複数選択の場合
  final int? count; // 複数選択で選ぶべき個数
  final String? unit; // 数値問題の単位
  final int? digits; // 数値問題の桁数
  final String? decimalRule; // 小数点以下の処理ルール

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) {
    return QuestionAnswer(
      type: json['type'] as String,
      value: json['value'] as int?,
      values: (json['values'] as List<dynamic>?)?.map((e) => e as int).toList(),
      count: json['count'] as int?,
      unit: json['unit'] as String?,
      digits: json['digits'] as int?,
      decimalRule: json['decimal_rule'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (value != null) 'value': value,
      if (values != null) 'values': values,
      if (count != null) 'count': count,
      if (unit != null) 'unit': unit,
      if (digits != null) 'digits': digits,
      if (decimalRule != null) 'decimal_rule': decimalRule,
    };
  }
}

class Question {
  const Question({
    required this.id,
    required this.mode,
    required this.domainId,
    required this.subdomainId,
    required this.format,
    required this.stem,
    required this.choices,
    required this.answer,
    required this.difficulty,
    required this.caseId,
    required this.year,
    required this.explainShort,
    required this.explainLong,
    required this.meta,
  });

  final String id;
  final String mode;
  final String domainId;
  final String subdomainId;
  final String format; // "single_choice", "multiple_choice", "numeric_input"
  final String stem;
  final List<QuestionChoice> choices;
  final QuestionAnswer answer;
  final double difficulty;
  final String? caseId;
  final int? year;
  final String? explainShort;
  final String? explainLong;
  final Map<String, dynamic> meta;

  factory Question.fromJson(Map<String, dynamic> json) {
    // 新フォーマットのみ対応
    final choicesRaw = json['choices'] as List<dynamic>? ?? [];
    final choices = choicesRaw
        .map((choice) => QuestionChoice.fromJson(choice as Map<String, dynamic>))
        .toList();

    final answer = QuestionAnswer.fromJson(json['answer'] as Map<String, dynamic>);

    return Question(
      id: json['id'] as String,
      mode: json['mode'] as String,
      domainId: json['domain_id'] as String,
      subdomainId: json['subdomain_id'] as String,
      format: json['format'] as String,
      stem: json['stem'] as String,
      choices: choices,
      answer: answer,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.5,
      caseId: json['case_id'] as String?,
      year: json['year'] as int?,
      explainShort: json['explain_short'] as String?,
      explainLong: json['explain_long'] as String?,
      meta: (json['meta'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  /// 正解かどうかを判定する
  bool isCorrect(dynamic userAnswer) {
    switch (answer.type) {
      case 'single':
        // 単一選択: userAnswer は選択肢のindex（int）
        return userAnswer is int && userAnswer == answer.value;
      
      case 'multiple':
        // 複数選択: userAnswer は選択したindexのリスト（List<int>）
        if (userAnswer is! List<int>) return false;
        final correctSet = answer.values?.toSet() ?? {};
        final userSet = userAnswer.toSet();
        return correctSet.length == userSet.length && 
               correctSet.containsAll(userSet);
      
      case 'numeric':
        // 数値入力: userAnswer は数値（int）
        return userAnswer is int && userAnswer == answer.value;
      
      default:
        return false;
    }
  }

  /// 選択肢のテキストを取得
  String getChoiceText(int index) {
    final choice = choices.firstWhere(
      (c) => c.index == index,
      orElse: () => choices.first,
    );
    return choice.text;
  }
}