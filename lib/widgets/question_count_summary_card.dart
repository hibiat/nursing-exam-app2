import 'package:flutter/material.dart';

/// 学習問題数サマリーカード
class QuestionCountSummaryCard extends StatelessWidget {
  const QuestionCountSummaryCard({
    super.key,
    required this.totalQuestions,
    required this.correctCount,
    required this.weeklyDifference,
  });

  final int totalQuestions;
  final int correctCount;
  final int weeklyDifference; // 先週比（問題数）

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = totalQuestions > 0
        ? (correctCount / totalQuestions * 100).round()
        : 0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '学習問題数',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  totalQuestions.toString(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '問',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '正答率 $accuracy%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  weeklyDifference >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 20,
                  color: weeklyDifference >= 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Text(
                  '先週比 ${weeklyDifference >= 0 ? '+' : ''}$weeklyDifference問',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: weeklyDifference >= 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
