import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/daily_study_stats.dart';

/// 棒グラフウィジェット（学習時間または問題数用）
class StudyBarChart extends StatelessWidget {
  const StudyBarChart({
    super.key,
    required this.dailyStats,
    required this.dataType, // 'time' or 'count'
  });

  final List<DailyStudyStats> dailyStats;
  final String dataType; // 'time' or 'count'

  @override
  Widget build(BuildContext context) {
    if (dailyStats.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('学習データがありません'),
        ),
      );
    }

    final theme = Theme.of(context);
    final barGroups = dailyStats.asMap().entries.map((entry) {
      final index = entry.key;
      final stats = entry.value;
      final value = dataType == 'time'
          ? stats.studyTimeMinutes.toDouble() // 分単位
          : stats.questionCount.toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: theme.colorScheme.primary,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    // Y軸の最大値を計算
    final maxValue = dailyStats
        .map((s) => dataType == 'time' ? s.studyTimeMinutes : s.questionCount)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    // 最小値を保証（0や極小値の場合のデフォルト）
    final maxY = maxValue > 0
        ? (maxValue * 1.2).ceilToDouble()
        : (dataType == 'time' ? 60.0 : 10.0); // 時間なら60分、問題数なら10問をデフォルト

    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: theme.textTheme.bodySmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dailyStats.length) {
                    return const Text('');
                  }
                  final date = dailyStats[index].date;
                  // 表示する日付を間引く（データが多い場合）
                  if (dailyStats.length > 14 && index % 2 != 0) {
                    return const Text('');
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('M/d').format(date),
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
              bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
          ),
          minY: 0,
          maxY: maxY,
          barGroups: barGroups,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final stats = dailyStats[group.x];
                final dateStr = DateFormat('M月d日').format(stats.date);
                final valueStr = dataType == 'time'
                    ? '${stats.studyTimeMinutes}分'
                    : '${stats.questionCount}問';
                return BarTooltipItem(
                  '$dateStr\n$valueStr',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
