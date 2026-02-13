import 'package:flutter/material.dart';

/// 学習時間サマリーカード
class StudyTimeSummaryCard extends StatelessWidget {
  const StudyTimeSummaryCard({
    super.key,
    required this.totalMinutes,
    required this.weeklyDifference,
    this.targetMinutesPerDay,
  });

  final int totalMinutes;
  final int weeklyDifference; // 先週比（分）
  final int? targetMinutesPerDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '学習時間',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (hours > 0) ...[
                  Text(
                    hours.toString(),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '時間',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  minutes.toString(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '分',
                  style: theme.textTheme.titleMedium?.copyWith(
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
                  '先週比 ${weeklyDifference >= 0 ? '+' : ''}$weeklyDifference分',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: weeklyDifference >= 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (targetMinutesPerDay != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '目標学習時間 $targetMinutesPerDay分/日',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
