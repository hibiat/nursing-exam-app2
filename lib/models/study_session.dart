/// 学習セッション情報（解答履歴タブ用）
class StudySession {
  const StudySession({
    required this.id,
    required this.startedAt,
    required this.correctCount,
    required this.totalCount,
    required this.mode,
    this.categoryName,
  });

  final String id;
  final DateTime startedAt;
  final int correctCount;
  final int totalCount;
  final String mode; // 'required' or 'general'
  final String? categoryName;

  /// 正答率（0.0 ~ 1.0）
  double get accuracy => totalCount > 0 ? correctCount / totalCount : 0.0;

  /// 正答率（パーセント表示用）
  int get accuracyPercent => (accuracy * 100).round();
}
