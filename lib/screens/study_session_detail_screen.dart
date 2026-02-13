import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/study_session.dart';
import '../models/attempt.dart';
import '../models/question.dart';
import '../repositories/attempt_repository.dart';
import '../services/question_set_service.dart';
import '../utils/user_friendly_error_messages.dart';

/// セッションデータ（Attempt と Question のマップ）
class _SessionData {
  final List<Attempt> attempts;
  final Map<String, Question> questionsMap;

  _SessionData(this.attempts, this.questionsMap);
}

/// 学習セッション詳細画面
class StudySessionDetailScreen extends StatelessWidget {
  const StudySessionDetailScreen({
    super.key,
    required this.session,
  });

  final StudySession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('M月d日 HH:mm');
    final modeLabel = session.mode == 'required' ? '必修' : '一般・状況設定';

    return Scaffold(
      appBar: AppBar(
        title: const Text('解答詳細'),
      ),
      body: FutureBuilder<_SessionData>(
        future: _fetchSessionData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error);
          }

          final data = snapshot.data;
          if (data == null || data.attempts.isEmpty) {
            return _buildEmptyState(context);
          }

          final attempts = data.attempts;
          final questionsMap = data.questionsMap;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // セッション情報ヘッダー
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateFormat.format(session.startedAt),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.quiz_outlined,
                            label: '${session.totalCount}問',
                            theme: theme,
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            icon: Icons.check_circle,
                            label: '正解 ${session.correctCount}問',
                            color: theme.colorScheme.primary,
                            theme: theme,
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            icon: Icons.cancel,
                            label: '不正解 ${session.totalCount - session.correctCount}問',
                            color: theme.colorScheme.error,
                            theme: theme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 問題ごとの解答詳細
              Text(
                '解答一覧',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...attempts.asMap().entries.map((entry) {
                final index = entry.key;
                final attempt = entry.value;
                final question = questionsMap[attempt.questionId];
                return _AttemptDetailCard(
                  attempt: attempt,
                  questionNumber: index + 1,
                  question: question,
                );
              }),
            ],
          );
        },
      ),
    );
  }

  /// セッションのデータ（Attempt と Question）を取得
  Future<_SessionData> _fetchSessionData() async {
    final repository = AttemptRepository();

    // セッション開始時刻の前後10分の範囲で取得
    final start = session.startedAt.subtract(const Duration(minutes: 1));
    final end = session.startedAt.add(const Duration(minutes: 15));

    final attempts = await repository.fetchAttemptsByDateRange(
      start,
      end,
      limit: session.totalCount + 10, // 余裕を持って取得
    );

    // answeredAt が session.startedAt に近い順にソート
    attempts.sort((a, b) => a.answeredAt.compareTo(b.answeredAt));

    final sessionAttempts = attempts.take(session.totalCount).toList();

    // 問題を取得
    final questionService = QuestionSetService();
    final setId = await questionService.loadActiveSetIdForMode(session.mode);

    Map<String, Question> questionsMap = {};

    if (setId != null) {
      try {
        final storagePath = 'question_sets/$setId/${session.mode}.jsonl';
        final questions = await questionService.loadQuestionsFromStorage(storagePath);

        // questionId でマップ化
        for (final q in questions) {
          questionsMap[q.id] = q;
        }
      } catch (e) {
        // 問題の取得に失敗しても、Attempt は表示する
        // 本番環境では適切なロギングサービスを使用すること
      }
    }

    return _SessionData(sessionAttempts, questionsMap);
  }

  Widget _buildErrorState(BuildContext context, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'データの取得に失敗しました',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              UserFriendlyErrorMessages.getErrorMessage(error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'セッションデータが見つかりませんでした',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
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
        Icon(icon, size: 16, color: displayColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: displayColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AttemptDetailCard extends StatelessWidget {
  const _AttemptDetailCard({
    required this.attempt,
    required this.questionNumber,
    this.question,
  });

  final Attempt attempt;
  final int questionNumber;
  final Question? question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect = attempt.isCorrect;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 問題番号
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      questionNumber.toString(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 正誤マーク
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isCorrect ? '正解' : '不正解',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isCorrect
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                // 解答時間
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(attempt.responseTimeMs / 1000).round()}秒',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 問題文
            if (question != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question!.stem,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              Text(
                '問題ID: ${attempt.questionId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // 解答内容
            if (attempt.isSkip) ...[
              const SizedBox(height: 4),
              Text(
                'スキップ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                '解答: ${_formatAnswer(attempt)}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatAnswer(Attempt attempt) {
    if (attempt.chosenSingle != null) {
      return '選択肢 ${attempt.chosenSingle}';
    } else if (attempt.chosenMultiple != null && attempt.chosenMultiple!.isNotEmpty) {
      return '選択肢 ${attempt.chosenMultiple!.join(', ')}';
    } else if (attempt.chosenNumeric != null) {
      return '${attempt.chosenNumeric}';
    }
    return '未回答';
  }
}
