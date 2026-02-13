import 'package:intl/intl.dart';

import '../models/score_engine.dart';
import '../repositories/score_history_repository.dart';
import 'user_score_service.dart';

/// スコアスナップショットを日次で保存するサービス
class ScoreSnapshotService {
  ScoreSnapshotService({
    UserScoreService? userScoreService,
    ScoreHistoryRepository? scoreHistoryRepository,
  })  : _userScoreService = userScoreService ?? UserScoreService(),
        _scoreHistoryRepository =
            scoreHistoryRepository ?? ScoreHistoryRepository();

  final UserScoreService _userScoreService;
  final ScoreHistoryRepository _scoreHistoryRepository;

  /// 現在のスコアをスナップショットとして保存
  /// 学習セッション終了時またはユニット完了時に呼び出す
  Future<void> saveCurrentScoreSnapshot() async {
    try {
      // 現在のスコアを取得
      final requiredScore = await _userScoreService.calculateRequiredScore();
      final generalScore = await _userScoreService.calculateGeneralScore();

      // ランクを計算
      final scoreEngine = ScoreEngine();
      final requiredRank = scoreEngine.requiredRankFromScore(requiredScore);
      final generalRank = scoreEngine.generalRankFromScore(generalScore);

      // 今日の日付を yyyy-MM-dd 形式で取得
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // スコアを保存
      await _scoreHistoryRepository.saveScoreSnapshot(
        date: today,
        requiredScore: requiredScore,
        generalScore: generalScore,
        requiredRank: requiredRank,
        generalRank: generalRank,
      );
    } catch (e) {
      // エラーが発生しても学習セッションは継続
      // 本番環境では適切なロギングサービスを使用すること
    }
  }

  /// 最後にスナップショットを保存した日付を取得
  Future<DateTime?> getLastSnapshotDate() async {
    final requiredPoint = await _scoreHistoryRepository.fetchLatestScore(
      mode: 'required',
    );

    if (requiredPoint == null) return null;
    return requiredPoint.date;
  }

  /// 今日スナップショットを保存済みかチェック
  Future<bool> isTodaySnapshotSaved() async {
    final lastDate = await getLastSnapshotDate();
    if (lastDate == null) return false;

    final today = DateTime.now();
    return lastDate.year == today.year &&
        lastDate.month == today.month &&
        lastDate.day == today.day;
  }
}
