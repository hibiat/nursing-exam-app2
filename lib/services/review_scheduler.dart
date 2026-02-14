import 'dart:math';

import '../models/attempt.dart';
import '../models/question.dart';
import '../models/question_state.dart';

/// 復習問題を選択するスケジューラ
/// 忘却曲線（Ebbinghaus式）に基づいて優先順位を計算
class ReviewScheduler {
  const ReviewScheduler();

  /// 復習対象の問題を選択
  ///
  /// アルゴリズム:
  /// 1. 各問題の忘却度スコアを計算: 1 - e^(-t/S)
  /// 2. 優先度 = lapses（失敗回数） × 忘却度スコア
  /// 3. 上位30%からランダム選択（偏り防止）
  String? selectReviewQuestion({
    required List<Question> candidates,
    required Map<String, QuestionState> questionStates,
    required Map<String, Attempt> lastAttempts,
    required DateTime now,
  }) {
    final scored = <_ScoredQuestion>[];

    for (final question in candidates) {
      final state = questionStates[question.id];
      final lastAttempt = lastAttempts[question.id];

      // 一度も間違えていない問題はスキップ
      if (state == null || state.lapses == 0) continue;

      // 最後の回答がない場合もスキップ
      if (lastAttempt == null) continue;

      // 忘却度スコアを計算
      final forgettingScore = _calculateForgettingScore(
        lastSeenAt: state.lastSeenAt,
        stability: state.stability,
        now: now,
      );

      // 優先度 = 失敗回数 × 忘却度スコア
      final priority = state.lapses * forgettingScore;

      scored.add(_ScoredQuestion(
        questionId: question.id,
        priority: priority,
      ));
    }

    if (scored.isEmpty) return null;

    // 優先度でソート（降順）
    scored.sort((a, b) => b.priority.compareTo(a.priority));

    // 上位30%からランダム選択
    final topCount = max(1, (scored.length * 0.3).ceil());
    final topScored = scored.take(topCount).toList();

    final randomIndex = Random().nextInt(topScored.length);
    return topScored[randomIndex].questionId;
  }

  /// 忘却度スコアを計算
  ///
  /// Ebbinghaus忘却曲線: R = e^(-t/S)
  /// R: 保持率
  /// t: 経過時間（日数）
  /// S: stability（記憶強度）
  ///
  /// 忘却度 = 1 - R （保持率が低いほど忘却度が高い）
  double _calculateForgettingScore({
    required DateTime lastSeenAt,
    required double stability,
    required DateTime now,
  }) {
    final elapsedTime = now.difference(lastSeenAt).inHours / 24.0; // 日数
    final retentionRate = exp(-elapsedTime / stability);
    final forgettingScore = 1.0 - retentionRate;

    // 0.0〜1.0の範囲にクランプ
    return forgettingScore.clamp(0.0, 1.0);
  }
}

/// 優先度付き問題
class _ScoredQuestion {
  const _ScoredQuestion({
    required this.questionId,
    required this.priority,
  });

  final String questionId;
  final double priority;
}
