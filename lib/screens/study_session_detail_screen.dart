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
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _AttemptDetailFullScreen(
                attempt: attempt,
                questionNumber: questionNumber,
                question: question,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 問題番号
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        questionNumber.toString(),
                        style: theme.textTheme.labelMedium?.copyWith(
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
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 問題文プレビュー
              if (question != null) ...[
                Text(
                  question!.stem,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else ...[
                Text(
                  '問題ID: ${attempt.questionId}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 解答詳細の全画面表示
class _AttemptDetailFullScreen extends StatelessWidget {
  const _AttemptDetailFullScreen({
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

    return Scaffold(
      appBar: AppBar(
        title: Text('問題 $questionNumber'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 正誤結果
            Card(
              color: isCorrect
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onErrorContainer,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isCorrect ? '正解' : '不正解',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: isCorrect
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 問題文
            Text(
              '問題文',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (question != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  question!.stem,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ] else ...[
              Text(
                '問題ID: ${attempt.questionId}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // 選択肢
            if (question != null && question!.choices.isNotEmpty) ...[
              Text(
                '選択肢',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...question!.choices.map((choice) {
                final isUserChoice = _isUserChoice(choice.index, attempt);
                final isCorrectChoice = _isCorrectChoice(choice.index, question!);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrectChoice
                          ? theme.colorScheme.primary
                          : (isUserChoice && !isCorrect
                              ? theme.colorScheme.error
                              : theme.colorScheme.outlineVariant),
                      width: isCorrectChoice || (isUserChoice && !isCorrect) ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 選択肢番号
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCorrectChoice
                                ? theme.colorScheme.primary
                                : (isUserChoice && !isCorrect
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.outlineVariant),
                            width: 2.5,
                          ),
                          color: isCorrectChoice
                              ? theme.colorScheme.primaryContainer
                              : (isUserChoice && !isCorrect
                                  ? theme.colorScheme.errorContainer
                                  : theme.colorScheme.surfaceContainerHighest),
                          boxShadow: isCorrectChoice || (isUserChoice && !isCorrect)
                              ? [
                                  BoxShadow(
                                    color: (isCorrectChoice
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.error)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${choice.index}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCorrectChoice
                                  ? theme.colorScheme.onPrimaryContainer
                                  : (isUserChoice && !isCorrect
                                      ? theme.colorScheme.onErrorContainer
                                      : theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 選択肢テキスト
                      Expanded(
                        child: Text(
                          choice.text,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // あなたの解答
            Text(
              'あなたの解答',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildAnswerDisplay(
              context: context,
              attempt: attempt,
              question: question,
              isUserAnswer: true,
              isCorrect: isCorrect,
            ),
            const SizedBox(height: 24),

            // 正解
            if (question != null && !isCorrect) ...[
              Text(
                '正解',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildCorrectAnswerDisplay(
                context: context,
                question: question!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatUserAnswer(Attempt attempt, Question? question) {
    if (attempt.isSkip) {
      return 'スキップ';
    }

    if (question == null) {
      if (attempt.chosenSingle != null) {
        return '選択肢 ${attempt.chosenSingle}';
      } else if (attempt.chosenMultiple != null && attempt.chosenMultiple!.isNotEmpty) {
        return '選択肢 ${attempt.chosenMultiple!.join(', ')}';
      } else if (attempt.chosenNumeric != null) {
        return '${attempt.chosenNumeric}';
      }
      return '未回答';
    }

    // 選択肢のテキストを表示
    if (attempt.chosenSingle != null) {
      final choice = question.choices.firstWhere(
        (c) => c.index == attempt.chosenSingle,
        orElse: () => question.choices.first,
      );
      return '${choice.index}. ${choice.text}';
    } else if (attempt.chosenMultiple != null && attempt.chosenMultiple!.isNotEmpty) {
      final texts = attempt.chosenMultiple!.map((idx) {
        final choice = question.choices.firstWhere(
          (c) => c.index == idx,
          orElse: () => question.choices.first,
        );
        return '${choice.index}. ${choice.text}';
      }).join('\n');
      return texts;
    } else if (attempt.chosenNumeric != null) {
      return '${attempt.chosenNumeric}';
    }
    return '未回答';
  }

  String _formatCorrectAnswer(Question question) {
    // 単一選択の場合
    if (question.answer.value != null) {
      final choice = question.choices.firstWhere(
        (c) => c.index == question.answer.value,
        orElse: () => question.choices.first,
      );
      return '${choice.index}. ${choice.text}';
    }

    // 複数選択の場合
    if (question.answer.values != null && question.answer.values!.isNotEmpty) {
      final texts = question.answer.values!.map((idx) {
        final choice = question.choices.firstWhere(
          (c) => c.index == idx,
          orElse: () => question.choices.first,
        );
        return '${choice.index}. ${choice.text}';
      }).join('\n');
      return texts;
    }

    return '正解情報なし';
  }

  bool _isUserChoice(int choiceIndex, Attempt attempt) {
    if (attempt.chosenSingle != null) {
      return attempt.chosenSingle == choiceIndex;
    }
    if (attempt.chosenMultiple != null) {
      return attempt.chosenMultiple!.contains(choiceIndex);
    }
    return false;
  }

  bool _isCorrectChoice(int choiceIndex, Question question) {
    if (question.answer.value != null) {
      return question.answer.value == choiceIndex;
    }
    if (question.answer.values != null) {
      return question.answer.values!.contains(choiceIndex);
    }
    return false;
  }

  /// ユーザーの解答を視覚的に表示
  Widget _buildAnswerDisplay({
    required BuildContext context,
    required Attempt attempt,
    required Question? question,
    required bool isUserAnswer,
    required bool isCorrect,
  }) {
    final theme = Theme.of(context);

    if (attempt.isSkip) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 2,
          ),
        ),
        child: Text(
          'スキップ',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    if (question == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCorrect ? theme.colorScheme.primary : theme.colorScheme.error,
            width: 2,
          ),
        ),
        child: Text(
          _formatUserAnswer(attempt, question),
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    // 選択肢をバッジ形式で表示
    List<int> choiceIndices = [];
    if (attempt.chosenSingle != null) {
      choiceIndices = [attempt.chosenSingle!];
    } else if (attempt.chosenMultiple != null && attempt.chosenMultiple!.isNotEmpty) {
      choiceIndices = attempt.chosenMultiple!;
    }

    if (choiceIndices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 2,
          ),
        ),
        child: Text(
          '未回答',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return Column(
      children: choiceIndices.map((choiceIdx) {
        final choice = question.choices.firstWhere(
          (c) => c.index == choiceIdx,
          orElse: () => question.choices.first,
        );

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCorrect ? theme.colorScheme.primary : theme.colorScheme.error,
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 選択肢番号バッジ
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCorrect ? theme.colorScheme.primary : theme.colorScheme.error,
                    width: 2.5,
                  ),
                  color: isCorrect
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.errorContainer,
                  boxShadow: [
                    BoxShadow(
                      color: (isCorrect ? theme.colorScheme.primary : theme.colorScheme.error)
                          .withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    '${choice.index}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCorrect
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 選択肢テキスト
              Expanded(
                child: Text(
                  choice.text,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 正解を視覚的に表示
  Widget _buildCorrectAnswerDisplay({
    required BuildContext context,
    required Question question,
  }) {
    final theme = Theme.of(context);

    List<int> correctIndices = [];
    if (question.answer.value != null) {
      correctIndices = [question.answer.value!];
    } else if (question.answer.values != null && question.answer.values!.isNotEmpty) {
      correctIndices = question.answer.values!;
    }

    if (correctIndices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '正解情報なし',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    return Column(
      children: correctIndices.map((choiceIdx) {
        final choice = question.choices.firstWhere(
          (c) => c.index == choiceIdx,
          orElse: () => question.choices.first,
        );

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 選択肢番号バッジ
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2.5,
                  ),
                  color: theme.colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    '${choice.index}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 選択肢テキスト
              Expanded(
                child: Text(
                  choice.text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
