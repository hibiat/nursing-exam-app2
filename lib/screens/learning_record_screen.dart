import 'package:flutter/material.dart';

import '../repositories/study_stats_repository.dart';
import '../models/daily_study_stats.dart';
import '../models/study_session.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/period_selector.dart';
import '../widgets/mode_filter_selector.dart';
import '../widgets/study_time_summary_card.dart';
import '../widgets/question_count_summary_card.dart';
import '../widgets/study_session_list_item.dart';
import '../utils/user_friendly_error_messages.dart';
import 'study_screen.dart';

/// 学習記録画面（3タブ: 学習時間/問題数/履歴）
class LearningRecordScreen extends StatefulWidget {
  const LearningRecordScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  State<LearningRecordScreen> createState() => _LearningRecordScreenState();
}

class _LearningRecordScreenState extends State<LearningRecordScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StudyStatsRepository _statsRepository = StudyStatsRepository();

  int _selectedPeriod = 7; // デフォルト: 1週間
  String _selectedMode = 'all'; // デフォルト: 全て ('all', 'required', 'general')

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('学習記録'),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '解答履歴'),
                  Tab(text: '学習時間'),
                  Tab(text: '学習問題数'),
                ],
              ),
            ),
      body: widget.isEmbedded
          ? Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '解答履歴'),
                    Tab(text: '学習時間'),
                    Tab(text: '学習問題数'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAnswerHistoryTab(),
                      _buildStudyTimeTab(),
                      _buildQuestionCountTab(),
                    ],
                  ),
                ),
              ],
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnswerHistoryTab(),
                _buildStudyTimeTab(),
                _buildQuestionCountTab(),
              ],
            ),
    );
  }

  /// 学習時間タブ
  Widget _buildStudyTimeTab() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: _selectedPeriod));

    return FutureBuilder<List<DailyStudyStats>>(
      future: _statsRepository.aggregateDailyStats(start, now, modeFilter: _selectedMode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        final stats = snapshot.data ?? [];

        if (stats.isEmpty) {
          return _buildEmptyState();
        }

        // 合計学習時間を計算
        final totalMinutes = stats
            .map((s) => s.studyTimeMinutes)
            .fold(0, (a, b) => a + b);

        return ListView(
          children: [
            // サマリーカード
            FutureBuilder<int>(
              future: _statsRepository.calculateWeeklyTimeDifference(),
              builder: (context, weeklySnapshot) {
                final weeklyDiff = weeklySnapshot.data ?? 0;
                return StudyTimeSummaryCard(
                  totalMinutes: totalMinutes,
                  weeklyDifference: weeklyDiff,
                  targetMinutesPerDay: 30, // TODO: ユーザー設定から取得
                );
              },
            ),

            // モードフィルタ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ModeFilterSelector(
                selectedMode: _selectedMode,
                onModeChanged: (mode) {
                  setState(() => _selectedMode = mode);
                },
              ),
            ),

            // 期間選択
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: PeriodSelector(
                selectedPeriod: _selectedPeriod,
                onPeriodChanged: (period) {
                  setState(() => _selectedPeriod = period);
                },
              ),
            ),

            // 棒グラフ
            SizedBox(
              height: 300,
              child: StudyBarChart(
                dailyStats: stats,
                dataType: 'time',
              ),
            ),

            // 教材別学習時間
            _buildModeBreakdownSection(stats, 'time'),
          ],
        );
      },
    );
  }

  /// 学習問題数タブ
  Widget _buildQuestionCountTab() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: _selectedPeriod));

    return FutureBuilder<List<DailyStudyStats>>(
      future: _statsRepository.aggregateDailyStats(start, now, modeFilter: _selectedMode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        final stats = snapshot.data ?? [];

        if (stats.isEmpty) {
          return _buildEmptyState();
        }

        // 合計問題数と正答数を計算
        final totalQuestions = stats
            .map((s) => s.questionCount)
            .fold(0, (a, b) => a + b);
        final totalCorrect = stats
            .map((s) => s.correctCount)
            .fold(0, (a, b) => a + b);

        return ListView(
          children: [
            // サマリーカード
            FutureBuilder<int>(
              future: _statsRepository.calculateWeeklyQuestionDifference(),
              builder: (context, weeklySnapshot) {
                final weeklyDiff = weeklySnapshot.data ?? 0;
                return QuestionCountSummaryCard(
                  totalQuestions: totalQuestions,
                  correctCount: totalCorrect,
                  weeklyDifference: weeklyDiff,
                );
              },
            ),

            // モードフィルタ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ModeFilterSelector(
                selectedMode: _selectedMode,
                onModeChanged: (mode) {
                  setState(() => _selectedMode = mode);
                },
              ),
            ),

            // 期間選択
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: PeriodSelector(
                selectedPeriod: _selectedPeriod,
                onPeriodChanged: (period) {
                  setState(() => _selectedPeriod = period);
                },
              ),
            ),

            // 棒グラフ
            SizedBox(
              height: 300,
              child: StudyBarChart(
                dailyStats: stats,
                dataType: 'count',
              ),
            ),

            // 教材別問題数
            _buildModeBreakdownSection(stats, 'count'),
          ],
        );
      },
    );
  }

  /// 解答履歴タブ
  Widget _buildAnswerHistoryTab() {
    return FutureBuilder<List<StudySession>>(
      future: _statsRepository.fetchStudySessions(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // 復習モードボタン
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _startReviewMode(context),
                icon: const Icon(Icons.replay),
                label: const Text('間違えた問題を復習する'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),
            // セッションリスト
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  return StudySessionListItem(session: sessions[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// エラー表示
  Widget _buildErrorState(Object? error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'データの取得に失敗しました',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            UserFriendlyErrorMessages.getErrorMessage(error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  /// データがない場合の表示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '学習データがまだありません',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '問題を解くと、ここに記録が表示されます',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('学習を始める'),
          ),
        ],
      ),
    );
  }

  /// 復習モードを開始
  Future<void> _startReviewMode(BuildContext context) async {
    // 各モードの復習対象数を取得
    final requiredCount = await _statsRepository.getReviewCandidateCount(mode: 'required');
    final generalCount = await _statsRepository.getReviewCandidateCount(mode: 'general');
    final totalCount = requiredCount + generalCount;

    if (totalCount == 0) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('復習する問題がありません'),
          content: const Text('間違えた問題がないか、すでに復習済みです。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final mode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('復習する問題の種類を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              enabled: requiredCount > 0,
              leading: Icon(
                Icons.local_hospital,
                color: requiredCount > 0
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
              ),
              title: Text(
                '必修問題',
                style: TextStyle(
                  color: requiredCount > 0
                      ? null
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                ),
              ),
              trailing: Text(
                '$requiredCount問',
                style: TextStyle(
                  color: requiredCount > 0
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: requiredCount > 0 ? () => Navigator.pop(context, 'required') : null,
            ),
            ListTile(
              enabled: generalCount > 0,
              leading: Icon(
                Icons.menu_book,
                color: generalCount > 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
              ),
              title: Text(
                '一般・状況設定',
                style: TextStyle(
                  color: generalCount > 0
                      ? null
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                ),
              ),
              trailing: Text(
                '$generalCount問',
                style: TextStyle(
                  color: generalCount > 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: generalCount > 0 ? () => Navigator.pop(context, 'general') : null,
            ),
          ],
        ),
      ),
    );

    if (mode != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudyScreen.review(mode: mode),
        ),
      );
    }
  }

  /// 教材別集計セクション
  Widget _buildModeBreakdownSection(List<DailyStudyStats> stats, String type) {
    // モードフィルタが「全て」以外の場合は表示しない
    if (_selectedMode != 'all') {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    // 各モードの合計を計算
    int requiredQuestions = 0;
    int generalQuestions = 0;
    int requiredTimeMs = 0;
    int generalTimeMs = 0;

    for (final stat in stats) {
      requiredQuestions += stat.questionsByMode['required'] ?? 0;
      generalQuestions += stat.questionsByMode['general'] ?? 0;
    }

    // 時間の場合は、問題数の割合で時間を按分
    if (type == 'time') {
      final totalQuestions = requiredQuestions + generalQuestions;
      if (totalQuestions > 0) {
        final totalTimeMs = stats.map((s) => s.totalStudyTimeMs).fold(0, (a, b) => a + b);
        requiredTimeMs = (totalTimeMs * requiredQuestions / totalQuestions).round();
        generalTimeMs = totalTimeMs - requiredTimeMs;
      }
    }

    final String title = type == 'time' ? '教材別学習時間' : '教材別問題数';
    final String requiredValue = type == 'time'
        ? '${(requiredTimeMs / 60000).round()}分'
        : '$requiredQuestions問';
    final String generalValue = type == 'time'
        ? '${(generalTimeMs / 60000).round()}分'
        : '$generalQuestions問';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.local_hospital, color: theme.colorScheme.error),
                  title: const Text('必修問題'),
                  trailing: Text(
                    requiredValue,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                ListTile(
                  leading: Icon(Icons.menu_book, color: theme.colorScheme.primary),
                  title: const Text('一般・状況設定'),
                  trailing: Text(
                    generalValue,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
