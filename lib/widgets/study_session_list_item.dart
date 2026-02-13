import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/study_session.dart';
import '../screens/study_session_detail_screen.dart';

/// 学習セッションリストアイテム
class StudySessionListItem extends StatelessWidget {
  const StudySessionListItem({
    super.key,
    required this.session,
  });

  final StudySession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('M月d日 HH:mm');
    final accuracy = session.totalCount > 0
        ? (session.correctCount / session.totalCount * 100).round()
        : 0;

    // モードの表示名
    final modeLabel = session.mode == 'required' ? '必修' : '一般・状況設定';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StudySessionDetailScreen(session: session),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 日時
                  Expanded(
                    child: Text(
                      dateFormat.format(session.startedAt),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // モードバッジ
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: session.mode == 'required'
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      modeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: session.mode == 'required'
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 統計情報
              Row(
                children: [
                  // 問題数
                  _StatItem(
                    icon: Icons.quiz_outlined,
                    label: '${session.totalCount}問',
                    theme: theme,
                  ),
                  const SizedBox(width: 16),
                  // 正答率
                  _StatItem(
                    icon: Icons.check_circle_outline,
                    label: '正答率 $accuracy%',
                    color: accuracy >= 70
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                    theme: theme,
                  ),
                ],
              ),
              if (session.categoryName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        session.categoryName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.theme,
    this.color,
  });

  final IconData icon;
  final String label;
  final ThemeData theme;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: displayColor,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: displayColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
