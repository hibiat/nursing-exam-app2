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
  final String format;
  final String stem;
  final List<String> choices;
  final String answer;
  final double difficulty;
  final String? caseId;
  final int? year;
  final String? explainShort;
  final String? explainLong;
  final Map<String, dynamic> meta;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      mode: json['mode'] as String,
      domainId: json['domain_id'] as String,
      subdomainId: json['subdomain_id'] as String,
      format: json['format'] as String? ?? 'single',
      stem: json['stem'] as String,
      choices: (json['choices'] as List<dynamic>? ?? [])
          .map((choice) => choice.toString())
          .toList(),
      answer: json['answer'] as String,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.5,
      caseId: json['case_id'] as String?,
      year: json['year'] as int?,
      explainShort: json['explain_short'] as String?,
      explainLong: json['explain_long'] as String?,
      meta: (json['meta'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }
}
