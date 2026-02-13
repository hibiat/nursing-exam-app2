/// 日別の学習統計データ
class DailyStudyStats {
  const DailyStudyStats({
    required this.date,
    required this.questionCount,
    required this.correctCount,
    required this.totalStudyTimeMs,
    required this.questionsByMode,
  });

  final DateTime date;
  final int questionCount;
  final int correctCount;
  final int totalStudyTimeMs;
  final Map<String, int> questionsByMode; // 'required' -> 10, 'general' -> 20

  /// 正答率（0.0 ~ 1.0）
  double get accuracy => questionCount > 0 ? correctCount / questionCount : 0.0;

  /// 学習時間（分）
  int get studyTimeMinutes => (totalStudyTimeMs / 60000).round();
}
