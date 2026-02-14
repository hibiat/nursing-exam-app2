import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/study_session.dart';
import '../repositories/attempt_repository.dart';
import '../services/question_set_service.dart';
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
    final modeLabel = session.mode == 'required' ? '必修' : '一般';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1行目: 日時 + モード + 正答率
              Row(
                children: [
                  // 日時
                  Text(
                    dateFormat.format(session.startedAt),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // モードバッジ
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
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
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 正答率アイコン
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: accuracy >= 70
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  // 正答率
                  Text(
                    '$accuracy%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: accuracy >= 70
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 2行目: 問題文プレビュー
              FutureBuilder<String?>(
                future: _fetchFirstQuestionText(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      '読み込み中...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }

                  final questionText = snapshot.data;
                  if (questionText == null || questionText.isEmpty) {
                    return Text(
                      'セッションID: ${session.startedAt.millisecondsSinceEpoch}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }

                  return Text(
                    questionText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 最初の問題の問題文を取得
  Future<String?> _fetchFirstQuestionText() async {
    try {
      // セッション開始時刻の前後で最初のAttemptを取得
      final repository = AttemptRepository();
      final start = session.startedAt.subtract(const Duration(minutes: 1));
      final end = session.startedAt.add(const Duration(minutes: 15));

      final attempts = await repository.fetchAttemptsByDateRange(
        start,
        end,
        limit: 1,
      );

      if (attempts.isEmpty) return null;

      final firstAttempt = attempts.first;

      // 問題を取得
      final questionService = QuestionSetService();
      final setId = await questionService.loadActiveSetIdForMode(session.mode);

      if (setId == null) return null;

      final storagePath = 'question_sets/$setId/${session.mode}.jsonl';
      final questions = await questionService.loadQuestionsFromStorage(storagePath);

      // 問題IDでマッチする問題を探す
      try {
        final question = questions.firstWhere(
          (q) => q.id == firstAttempt.questionId,
        );
        return question.stem.isNotEmpty ? question.stem : null;
      } catch (e) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
