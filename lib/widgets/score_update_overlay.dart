import 'package:flutter/material.dart';
import '../models/skill_progress.dart';
import '../constants/encouragement_messages.dart';
import '../constants/app_colors.dart';

class ScoreUpdateOverlay extends StatelessWidget {
  const ScoreUpdateOverlay({
    super.key,
    required this.rank,
    required this.lastRank,
    required this.overallScore,
    required this.skillProgress,
    required this.showStreakPraise,
    required this.streakMessage,
    required this.streakCount,
    required this.requiredBorderLabel,
    required this.onClose,
  });

  final String? rank;
  final String? lastRank;
  final double overallScore;
  final List<SkillProgress> skillProgress;
  final bool showStreakPraise;
  final String? streakMessage;
  final int streakCount;
  final String? requiredBorderLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // スコア変化の判定
    final hasImprovement = skillProgress.any((p) => p.currentScore > p.previousScore);
    final hasDecline = skillProgress.any((p) => p.currentScore < p.previousScore);
    
    String encouragementMessage;
    if (hasImprovement && !hasDecline) {
      // 全体的に上昇
      final bestDomain = skillProgress
          .reduce((a, b) => 
              (b.currentScore - b.previousScore) > (a.currentScore - a.previousScore) ? b : a)
          .label;
      encouragementMessage = EncouragementMessages.randomScoreUp(domain: bestDomain);
    } else if (hasDecline && !hasImprovement) {
      // 全体的に下降
      encouragementMessage = EncouragementMessages.randomScoreDown();
    } else if (hasImprovement && hasDecline) {
      // 混在
      encouragementMessage = '得意な領域を伸ばしつつ、弱点も克服していこう! 💪';
    } else {
      // 変化なし
      encouragementMessage = EncouragementMessages.randomScoreStable();
    }

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // タイトル
                  Icon(
                    Icons.auto_graph,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'スコア更新',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 励ましメッセージ
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
                  const SizedBox(height: 16),
                  
                  // 総合ランク表示
                  if (rank != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (lastRank != null) ...[
                          _RankBadge(rank: lastRank!, size: 40, opacity: 0.5),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.arrow_forward,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                        ],
                        _RankBadge(rank: rank!, size: 56),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '現在のランク: $rank',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 連続ログインメッセージ
                  if (showStreakPraise && streakMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.scoreUp.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: AppColors.scoreUp,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            streakMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.scoreUp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 必修ボーダーラベル
                  if (requiredBorderLabel != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getBorderLabelColor(requiredBorderLabel!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '必修: $requiredBorderLabel',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 領域別スコア変化
                  Text(
                    '領域別スコア変化',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  ...skillProgress.map(
                    (progress) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SkillProgressBar(progress: progress),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 閉じるボタン
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onClose,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('次の問題へ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBorderLabelColor(String label) {
    switch (label) {
      case '余裕':
        return AppColors.success;
      case '安定':
        return AppColors.primary;
      case '注意':
        return AppColors.warning;
      case '危険':
        return AppColors.scoreDown;
      default:
        return AppColors.textSecondary;
    }
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