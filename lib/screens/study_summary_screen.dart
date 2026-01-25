import 'package:flutter/material.dart';
import '../models/skill_progress.dart';
import '../constants/encouragement_messages.dart';
import '../constants/app_colors.dart';

/// 学習終了時のサマリー画面
class StudySummaryScreen extends StatelessWidget {
  const StudySummaryScreen({
    super.key,
    required this.questionsAnswered,
    required this.correctCount,
    required this.skillProgress,
    required this.rank,
    required this.lastRank,
    required this.overallScoreDelta,
  });

  final int questionsAnswered;
  final int correctCount;
  final List<SkillProgress> skillProgress;
  final String? rank;
  final String? lastRank;
  final double overallScoreDelta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correctRate = questionsAnswered > 0 
        ? (correctCount / questionsAnswered * 100).toInt()
        : 0;

    // 励ましメッセージ
    String encouragementMessage;
    if (correctRate >= 80) {
      encouragementMessage = EncouragementMessages.randomGoalComplete();
    } else if (correctRate >= 60) {
      encouragementMessage = EncouragementMessages.randomScoreStable();
    } else {
      encouragementMessage = '次はもっと良くなるよ! 一緒に頑張ろう 💪';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('学習サマリー'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // お疲れ様カード
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.celebration,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'お疲れさまでした!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        encouragementMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 学習実績
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日の学習実績',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.quiz,
                          label: '解いた問題',
                          value: '$questionsAnswered問',
                          color: AppColors.primary,
                        ),
                        _StatItem(
                          icon: Icons.check_circle,
                          label: '正解数',
                          value: '$correctCount問',
                          color: AppColors.success,
                        ),
                        _StatItem(
                          icon: Icons.percent,
                          label: '正答率',
                          value: '$correctRate%',
                          color: correctRate >= 70 
                              ? AppColors.success 
                              : AppColors.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // スコア変化
            if (rank != null) ...[
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'スコア変化',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (lastRank != null) ...[
                            _RankBadge(rank: lastRank!, size: 40, opacity: 0.5),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.arrow_forward,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 16),
                          ],
                          _RankBadge(rank: rank!, size: 56),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '現在のランク: $rank',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (overallScoreDelta != 0) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            overallScoreDelta > 0 
                                ? '+${overallScoreDelta.toStringAsFixed(1)}点'
                                : '${overallScoreDelta.toStringAsFixed(1)}点',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: overallScoreDelta > 0 
                                  ? AppColors.scoreUp 
                                  : AppColors.scoreDown,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 領域別スコア変化
            if (skillProgress.isNotEmpty) ...[
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '領域別スコア変化',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...skillProgress.map(
                        (progress) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SkillProgressBar(progress: progress),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ボタン
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'ホームに戻る',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({
    required this.rank,
    required this.size,
    this.opacity = 1.0,
  });

  final String rank;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (rank) {
      case 'S':
      case 'A':
        color = AppColors.success;
        break;
      case 'B':
        color = AppColors.primary;
        break;
      case 'C':
        color = AppColors.warning;
        break;
      case 'D':
        color = AppColors.scoreDown;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        shape: BoxShape.circle,
        boxShadow: opacity == 1.0
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        rank,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SkillProgressBar extends StatelessWidget {
  const _SkillProgressBar({required this.progress});

  final SkillProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = progress.currentScore - progress.previousScore;
    final isImproved = delta > 0;
    final isDeclined = delta < 0;
    
    Color barColor;
    IconData icon;
    
    if (isImproved) {
      barColor = AppColors.scoreUp;
      icon = Icons.trending_up;
    } else if (isDeclined) {
      barColor = AppColors.scoreDown;
      icon = Icons.trending_down;
    } else {
      barColor = AppColors.textSecondary;
      icon = Icons.trending_flat;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                progress.label,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(icon, size: 16, color: barColor),
            const SizedBox(width: 4),
            Text(
              delta >= 0 ? '+${delta.toStringAsFixed(1)}' : delta.toStringAsFixed(1),
              style: theme.textTheme.bodySmall?.copyWith(
                color: barColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (progress.currentScore / 100).clamp(0, 1),
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }
}