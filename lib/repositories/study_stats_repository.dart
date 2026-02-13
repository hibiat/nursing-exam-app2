import 'package:intl/intl.dart';

import '../models/attempt.dart';
import '../models/daily_study_stats.dart';
import '../models/study_session.dart';
import 'attempt_repository.dart';

class StudyStatsRepository {
  StudyStatsRepository({AttemptRepository? attemptRepository})
      : _attemptRepository = attemptRepository ?? AttemptRepository();

  final AttemptRepository _attemptRepository;

  /// 指定期間の日別統計を集計
  Future<List<DailyStudyStats>> aggregateDailyStats(
    DateTime start,
    DateTime end,
  ) async {
    final attempts = await _attemptRepository.fetchAttemptsByDateRange(start, end);

    if (attempts.isEmpty) return [];

    // 日付をキーにグループ化
    final Map<String, List<Attempt>> groupedByDate = {};
    for (final attempt in attempts) {
      final dateKey = DateFormat('yyyy-MM-dd').format(attempt.answeredAt);
      groupedByDate.putIfAbsent(dateKey, () => []).add(attempt);
    }

    // 各日付の統計を計算
    final stats = groupedByDate.entries.map((entry) {
      final date = DateTime.parse(entry.key);
      final dayAttempts = entry.value;

      final questionCount = dayAttempts.length;
      final correctCount = dayAttempts.where((a) => a.isCorrect).length;
      final totalStudyTimeMs = dayAttempts
          .map((a) => a.responseTimeMs)
          .fold(0, (a, b) => a + b);

      final questionsByMode = <String, int>{};
      for (final attempt in dayAttempts) {
        questionsByMode[attempt.mode] =
            (questionsByMode[attempt.mode] ?? 0) + 1;
      }

      return DailyStudyStats(
        date: date,
        questionCount: questionCount,
        correctCount: correctCount,
        totalStudyTimeMs: totalStudyTimeMs,
        questionsByMode: questionsByMode,
      );
    }).toList();

    // 日付順にソート
    stats.sort((a, b) => a.date.compareTo(b.date));

    return stats;
  }

  /// 学習セッション一覧を取得
  /// セッションは answeredAt が近い（例: 10分以内）の Attempt をグループ化して生成
  Future<List<StudySession>> fetchStudySessions({int limit = 50}) async {
    // 直近3ヶ月分のデータを取得
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 90));

    final attempts = await _attemptRepository.fetchAttemptsByDateRange(
      start,
      end,
      limit: limit * 10, // セッション化するため、多めに取得
    );

    if (attempts.isEmpty) return [];

    // セッション化（10分以内の Attempt を同じセッションとみなす）
    final sessions = <StudySession>[];
    List<Attempt> currentSessionAttempts = [];
    DateTime? lastAttemptTime;

    for (final attempt in attempts) {
      if (lastAttemptTime == null ||
          lastAttemptTime.difference(attempt.answeredAt).inMinutes.abs() <= 10) {
        // 同じセッション
        currentSessionAttempts.add(attempt);
        lastAttemptTime = attempt.answeredAt;
      } else {
        // 新しいセッション開始
        if (currentSessionAttempts.isNotEmpty) {
          sessions.add(_createSession(currentSessionAttempts));
        }
        currentSessionAttempts = [attempt];
        lastAttemptTime = attempt.answeredAt;
      }
    }

    // 最後のセッションを追加
    if (currentSessionAttempts.isNotEmpty) {
      sessions.add(_createSession(currentSessionAttempts));
    }

    return sessions.take(limit).toList();
  }

  /// Attempt のリストからセッションを生成
  StudySession _createSession(List<Attempt> attempts) {
    final correctCount = attempts.where((a) => a.isCorrect).length;
    final totalCount = attempts.length;
    final mode = attempts.first.mode;
    final startedAt = attempts.last.answeredAt; // リストは降順なので last が開始時刻

    // カテゴリ名は domainId から生成
    String? categoryName;
    final domainId = attempts.first.domainId;
    if (domainId.isNotEmpty && domainId != 'all') {
      categoryName = _getDomainDisplayName(domainId);
    }

    return StudySession(
      id: '${startedAt.millisecondsSinceEpoch}',
      startedAt: startedAt,
      correctCount: correctCount,
      totalCount: totalCount,
      mode: mode,
      categoryName: categoryName,
    );
  }

  /// ドメインIDを表示用の名前に変換
  String _getDomainDisplayName(String domainId) {
    // 一般的なドメインIDのマッピング
    final domainMap = {
      'required.core': '必修問題',
      'general.fundamental': '基礎看護学',
      'general.adult': '成人看護学',
      'general.pediatric': '小児看護学',
      'general.maternity': '母性看護学',
      'general.mental': '精神看護学',
      'general.geriatric': '老年看護学',
      'general.home': '在宅看護論',
      'general.integrated': '統合と実践',
    };

    return domainMap[domainId] ?? 'その他';
  }

  /// 先週比の計算（学習時間）
  Future<int> calculateWeeklyTimeDifference() async {
    final now = DateTime.now();
    final thisWeekStart = _getWeekStart(now);
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    final thisWeek = await aggregateDailyStats(thisWeekStart, now);
    final lastWeek = await aggregateDailyStats(lastWeekStart, thisWeekStart);

    final thisWeekTotal = thisWeek
        .map((s) => s.totalStudyTimeMs)
        .fold(0, (a, b) => a + b);

    final lastWeekTotal = lastWeek
        .map((s) => s.totalStudyTimeMs)
        .fold(0, (a, b) => a + b);

    return ((thisWeekTotal - lastWeekTotal) / 60000).round(); // 分単位
  }

  /// 先週比の計算（問題数）
  Future<int> calculateWeeklyQuestionDifference() async {
    final now = DateTime.now();
    final thisWeekStart = _getWeekStart(now);
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    final thisWeek = await aggregateDailyStats(thisWeekStart, now);
    final lastWeek = await aggregateDailyStats(lastWeekStart, thisWeekStart);

    final thisWeekTotal = thisWeek
        .map((s) => s.questionCount)
        .fold(0, (a, b) => a + b);

    final lastWeekTotal = lastWeek
        .map((s) => s.questionCount)
        .fold(0, (a, b) => a + b);

    return thisWeekTotal - lastWeekTotal;
  }

  /// 週の開始日（月曜日）を取得
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }
}
