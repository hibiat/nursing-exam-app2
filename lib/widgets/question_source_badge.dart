import 'package:flutter/material.dart';
import '../models/question_source.dart';

/// 問題の出典情報バッジ
class QuestionSourceBadge extends StatelessWidget {
  const QuestionSourceBadge({
    super.key,
    required this.source,
    this.compact = false,
  });

  final QuestionSource? source;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (source == null) return const SizedBox.shrink();
    
    final text = compact ? source!.toCompactText() : source!.toDisplayText();
    if (text.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            source!.getIcon(),
            size: compact ? 12 : 14,
            color: source!.getIconColor(context),
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            text,
            style: (compact 
              ? theme.textTheme.labelSmall 
              : theme.textTheme.bodySmall
            )?.copyWith(
              color: source!.getIconColor(context),
              fontWeight: FontWeight.bold,
              fontSize: compact ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (source!.type) {
      case 'past_exam':
        return cs.primaryContainer.withOpacity(0.4);
      case 'prediction':
        return cs.tertiaryContainer.withOpacity(0.4);
      case 'original':
        return cs.secondaryContainer.withOpacity(0.4);
      default:
        return cs.surfaceVariant.withOpacity(0.4);
    }
  }
}