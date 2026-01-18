import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 合格予測を表示するカード
class PassingPredictionCard extends StatelessWidget {
  const PassingPredictionCard({super.key});

  // TODO: 実際のスコアデータから計算
  // 仮の値を返す
  _PassingPredictionData _getPredictionData() {
    // 仮: ランクB、合格ライン内
    return _PassingPredictionData(
      currentRank: 'B',
      passingRank: 'B',
      isPassing: true,
      passingProbability: 0.75,
      pointsToPass: 0, // 合格圏内なので0
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _getPredictionData();
    final theme = Theme.of(context);
    
    Color statusColor;
    IconData statusIcon;
    String statusMessage;
    
    if (data.isPassing) {
      statusColor = AppColors.passingSafe;
      statusIcon = Icons.check_circle;
      statusMessage = '合格圏内です 🎉';
    } else if (data.pointsToPass <= 50) {
      statusColor = AppColors.passingBorder;
      statusIcon = Icons.trending_up;
      statusMessage = 'あと少しで合格ライン!';
    } else {
      statusColor = AppColors.passingRisk;
      statusIcon = Icons.school;
      statusMessage = '一緒に頑張りましょう 💪';
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
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoChip(
                  label: '現在のランク',
                  value: data.currentRank,
                  color: statusColor,
                ),
                _InfoChip(
                  label: '合格ライン',
                  value: '${data.passingRank}以上',
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 合格確率
            Row(
              children: [
                Text(
                  '合格予測: ',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '${(data.passingProbability * 100).toInt()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // プログレスバー
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: data.passingProbability,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
            if (!data.isPassing && data.pointsToPass > 0) ...[
              const SizedBox(height: 12),
              Text(
                '合格ラインまで: あと約+${data.pointsToPass}点',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _PassingPredictionData {
  const _PassingPredictionData({
    required this.currentRank,
    required this.passingRank,
    required this.isPassing,
    required this.passingProbability,
    required this.pointsToPass,
  });

  final String currentRank;
  final String passingRank;
  final bool isPassing;
  final double passingProbability; // 0.0 - 1.0
  final int pointsToPass; // 合格ラインまでのポイント差
}
