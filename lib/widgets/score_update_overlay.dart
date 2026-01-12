import 'package:flutter/material.dart';

import '../models/skill_progress.dart';

class ScoreUpdateOverlay extends StatefulWidget {
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
  State<ScoreUpdateOverlay> createState() => _ScoreUpdateOverlayState();
}

class _ScoreUpdateOverlayState extends State<ScoreUpdateOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'スコア更新',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '総合スコア',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.rank ?? '-',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '前回 ${widget.lastRank ?? '-'} → 今回 ${widget.rank ?? '-'}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '総合スコア ${widget.overallScore.toStringAsFixed(0)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '領域スキル',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 240,
                      child: widget.skillProgress.isEmpty
                          ? Center(
                              child: Text(
                                'スキルデータがありません',
                                style: theme.textTheme.bodySmall,
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: widget.skillProgress
                                    .map((progress) => _SkillProgressTile(progress: progress))
                                    .toList(),
                              ),
                            ),
                    ),
                    if (widget.showStreakPraise)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.streakMessage ?? '連続学習${widget.streakCount}日目！',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    if (widget.requiredBorderLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text('必修ボーダー余裕度: ${widget.requiredBorderLabel}'),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onClose,
                            child: const Text('閉じる'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: widget.onClose,
                            child: const Text('OK'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillProgressTile extends StatelessWidget {
  const _SkillProgressTile({required this.progress});

  final SkillProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previous = progress.previousScore;
    final current = progress.currentScore;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progress.label,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Text(
                '${previous.toStringAsFixed(0)} → ${current.toStringAsFixed(0)}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: previous, end: current),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (value / 100).clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
