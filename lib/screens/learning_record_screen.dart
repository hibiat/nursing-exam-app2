import 'package:flutter/material.dart';

import '../repositories/study_stats_repository.dart';
import '../models/daily_study_stats.dart';
import '../models/study_session.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/period_selector.dart';
import '../widgets/study_time_summary_card.dart';
import '../widgets/question_count_summary_card.dart';
import '../widgets/study_session_list_item.dart';
import '../utils/user_friendly_error_messages.dart';

/// 学習記録画面（3タブ: 学習時間/問題数/履歴）
class LearningRecordScreen extends StatefulWidget {
  const LearningRecordScreen({super.key});

  @override
  State<LearningRecordScreen> createState() => _LearningRecordScreenState();
}

class _LearningRecordScreenState extends State<LearningRecordScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StudyStatsRepository _statsRepository = StudyStatsRepository();

  int _selectedPeriod = 7; // デフォルト: 1週間

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
      appBar: AppBar(
        title: const Text('学習記録'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '学習時間'),
            Tab(text: '学習問題数'),
            Tab(text: '解答履歴'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudyTimeTab(),
          _buildQuestionCountTab(),
          _buildAnswerHistoryTab(),
        ],
      ),
    );
  }

  /// 学習時間タブ
  Widget _buildStudyTimeTab() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: _selectedPeriod));

    return FutureBuilder<List<DailyStudyStats>>(
      future: _statsRepository.aggregateDailyStats(start, now),
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

            // 教材別学習時間（TODO: 実装予定）
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '教材別学習時間',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '実装予定',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
      future: _statsRepository.aggregateDailyStats(start, now),
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

            // 教材別問題数（TODO: 実装予定）
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '教材別問題数',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '実装予定',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            return StudySessionListItem(session: sessions[index]);
          },
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
}
