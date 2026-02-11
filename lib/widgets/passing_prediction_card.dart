import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/user_friendly_explanations.dart';
import '../screens/domain_scores_screen.dart';
import '../services/user_score_service.dart';
import '../utils/user_friendly_error_messages.dart';

/// 合格予測を表示するカード
class PassingPredictionCard extends StatelessWidget {
  const PassingPredictionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final userScoreService = UserScoreService();

    return FutureBuilder<PassingPredictionData>(
      future: userScoreService.getPredictionData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.all(16),
            child: Container(
              height: 200,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(UserFriendlyErrorMessages.getErrorMessage(snapshot.error)),
            ),
          );
        }

        final data = snapshot.data!;
        return _PassingPredictionCardContent(data: data);
      },
    );
  }
}

class _PassingPredictionCardContent extends StatelessWidget {
  const _PassingPredictionCardContent({required this.data});

  final PassingPredictionData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String statusMessage;

    if (data.isPassing) {
      statusColor = AppColors.passingSafe;
      statusIcon = Icons.check_circle_outline;
      statusMessage = '合格ラインを超えています 👍';
    } else if (data.requiredGap <= 5 && data.generalGap <= 25) {
      statusColor = AppColors.passingBorder;
      statusIcon = Icons.trending_up;
      statusMessage = 'あと少しで合格ライン! 弱点を強化しよう 💪';
    } else {
      statusColor = AppColors.passingRisk;
      statusIcon = Icons.school;
      statusMessage = '基礎から積み上げていきましょう 📚';
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusMessage,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.info_outline, color: AppColors.textSecondary),
                  onPressed: () => _showCriteriaDialog(context),
                  tooltip: '合格基準について',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ScoreChip(
                  label: '必修',
                  score: '${data.requiredScore.toStringAsFixed(1)}点',
                  maxScore: '50点',
                  rank: data.requiredRank,
                  color: _getRankColor(data.requiredRank),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DomainScoresScreen(mode: 'required'),
                      ),
                    );
                  },
                ),
                _ScoreChip(
                  label: '一般・状況',
                  score: '${data.generalScore.toStringAsFixed(1)}点',
                  maxScore: '250点',
                  rank: data.generalRank,
                  color: _getRankColor(data.generalRank),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DomainScoresScreen(mode: 'general'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'S':
      case 'A':
        return AppColors.success;
      case 'B':
        return AppColors.primary;
      case 'C':
        return AppColors.warning;
      case 'D':
        return AppColors.scoreDown;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showCriteriaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('看護師国家試験 合格基準'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(UserFriendlyExplanations.getCalculationBasis()),
              const SizedBox(height: 12),
              const Text(
                '■ このアプリのランク',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _RankRow('S', '高得点域', AppColors.success),
              _RankRow('A', '安定域', AppColors.success),
              _RankRow('B', '合格ライン域', AppColors.primary),
              _RankRow('C', '要注意域', AppColors.warning),
              _RankRow('D', '基礎固め域', AppColors.scoreDown),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.score,
    required this.maxScore,
    required this.rank,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String score;
  final String maxScore;
  final String rank;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      score,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / $maxScore',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ランク$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'タップで分野別',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow(this.rank, this.label, this.color);

  final String rank;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              rank,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
