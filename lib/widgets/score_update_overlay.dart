import 'package:flutter/material.dart';

class ScoreUpdateOverlay extends StatelessWidget {
  const ScoreUpdateOverlay({
    super.key,
    required this.rank,
    required this.lastRank,
    required this.subdomainScore,
    required this.showStreakPraise,
    required this.showRequiredBorder,
    required this.onClose,
  });

  final String? rank;
  final String? lastRank;
  final double subdomainScore;
  final bool showStreakPraise;
  final bool showRequiredBorder;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ランク更新',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  '${lastRank ?? '-'} → ${rank ?? '-'}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('根拠バー'),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: subdomainScore),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value / 100,
                      minHeight: 12,
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (showStreakPraise)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('連続学習3日目！素晴らしいです！'),
                  ),
                if (showRequiredBorder)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('必修ボーダー余裕度: 安定'),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onClose,
                  child: const Text('続ける'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
