import 'dart:async';

import 'package:flutter/material.dart';

import '../models/question.dart';
import '../repositories/user_settings_repository.dart';
import '../services/user_score_service.dart';
import '../state/study_session_controller.dart';
import '../widgets/question_answer_widget.dart';
import '../widgets/question_source_badge.dart';
import 'study_summary_screen.dart';
import '../utils/user_friendly_error_messages.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({
    super.key,
    required this.mode,
    required this.domainId,
    required this.subdomainId,
  })  : isRecommendedMode = false,
        isReviewMode = false;

  const StudyScreen.recommended({
    super.key,
    required this.mode,
  })  : domainId = 'all',
        subdomainId = 'all',
        isRecommendedMode = true,
        isReviewMode = false;

  const StudyScreen.review({
    super.key,
    required this.mode,
  })  : domainId = 'all',
        subdomainId = 'all',
        isRecommendedMode = false,
        isReviewMode = true;

  final String mode;
  final String domainId;
  final String subdomainId;
  final bool isRecommendedMode;
  final bool isReviewMode;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  late final StudySessionController controller;
  late final Future<void> _initFuture;
  Timer? timer;
  int elapsedMs = 0;
  int remainingMs = 0;
  bool answered = false;
  dynamic _userAnswer; // int, List<int>, または null
  String? confidence;
  bool lastWasSkip = false;
  bool lastTimeExpired = false;
  static const int _timerTickMs = 1000;
  int _timeLimitMs = UserSettingsRepository.defaultTimeLimitSeconds * 1000;
  bool _showTimer = false;
  String? _activeQuestionId;
  Question? _displayQuestion;
  
  // 学習統計
  int _totalAnswered = 0;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    controller = StudySessionController(
      mode: widget.mode,
      domainId: widget.domainId,
      subdomainId: widget.subdomainId,
      unitTarget: 5,
      isRecommendedMode: widget.isRecommendedMode,
      isReviewMode: widget.isReviewMode,
    );
    controller.addListener(_onUpdate);
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    final settings = await UserSettingsRepository().fetchSettings();
    _timeLimitMs = settings.timeLimitSeconds * 1000;
    _showTimer = settings.showTimer;
    remainingMs = _timeLimitMs;
    await controller.start();
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.removeListener(_onUpdate);
    controller.dispose();
    super.dispose();
  }

  void _onUpdate() {
    final nextQuestion = controller.currentQuestion;
    final nextId = nextQuestion?.id;
    if (nextId != null && nextId != _activeQuestionId) {
      setState(() {
        _activeQuestionId = nextId;
        _displayQuestion = nextQuestion;
        answered = false;
        _userAnswer = null;
        confidence = null;
        lastWasSkip = false;
        lastTimeExpired = false;
        elapsedMs = 0;
        remainingMs = _timeLimitMs;
      });
      _startTimer();
      return;
    }
    setState(() {});
  }

  void _submit({required dynamic answer, required bool isSkip, required bool timeExpired}) {
    if (answered) return;
    
    final question = _displayQuestion ?? controller.currentQuestion;
    if (question == null) return;
    
    // 統計を更新
    if (!timeExpired) {
      _totalAnswered++;
      final isCorrect = !isSkip && question.isCorrect(answer);
      if (isCorrect) {
        _correctCount++;
      }
    }
    
    setState(() {
      answered = true;
      _userAnswer = answer;
      lastWasSkip = isSkip;
      lastTimeExpired = timeExpired;
      if (timeExpired) {
        remainingMs = 0;
      }
    });
    timer?.cancel();
    
    controller.submitAnswer(
      userAnswer: answer,
      isSkip: isSkip,
      responseTimeMs: elapsedMs,
      timeExpired: timeExpired,
      confidence: confidence,
      advanceAfterSubmit: false,
    );
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: _timerTickMs), (_) {
      if (answered) return;
      setState(() {
        remainingMs = (remainingMs - _timerTickMs).clamp(0, _timeLimitMs);
        elapsedMs = (_timeLimitMs - remainingMs).clamp(0, _timeLimitMs);
      });
      if (remainingMs <= 0 && !answered) {
        _submit(answer: null, isSkip: false, timeExpired: true);
      }
    });
  }

  Future<void> _showFinishConfirmDialog() async {
    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('学習を終了しますか?'),
        content: Text('今日は$_totalAnswered問解きました。\nサマリーを確認しますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('終了してサマリーを見る'),
          ),
        ],
      ),
    );

    if (shouldFinish == true && mounted) {
      // ホーム画面と同じ総合ランクを取得（全スキルの平均）
      final userScoreService = UserScoreService();
      final predictionData = await userScoreService.getPredictionData();

      print('🎯 Rank Debug:');
      print('  mode: ${widget.mode}');
      print('  requiredScore: ${predictionData.requiredScore}');
      print('  requiredRank: ${predictionData.requiredRank}');
      print('  generalScore: ${predictionData.generalScore}');
      print('  generalRank: ${predictionData.generalRank}');
      print('  controller.overallRank: ${controller.overallRank}');
      print('  controller.overallScore: ${controller.overallScore}');

      // 学習モードに応じて適切なランクを取得
      final currentRank = widget.mode == 'required'
          ? predictionData.requiredRank
          : predictionData.generalRank;

      print('  -> currentRank: $currentRank');

      // 学習開始前のランクは controller から取得
      final previousRank = controller.lastOverallRank;

      // スコア変化は controller から取得（学習したスキルのスコア変化）
      final scoreDelta = controller.overallScore - controller.lastOverallScore;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StudySummaryScreen(
            questionsAnswered: _totalAnswered,
            correctCount: _correctCount,
            skillProgress: controller.latestSkillProgress,
            rank: currentRank,
            lastRank: previousRank,
            overallScoreDelta: scoreDelta,
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(UserFriendlyErrorMessages.getErrorMessage(snapshot.error)),
            ),
          );
        }
        return _buildContent(context);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (controller.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.loadError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(UserFriendlyErrorMessages.getErrorMessage(controller.loadError)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: controller.start,
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    final question = _displayQuestion ?? controller.currentQuestion;
    if (question == null) {
      return const Scaffold(
        body: Center(child: Text('問題がありません')),
      );
    }

    final timeProgress = (remainingMs / _timeLimitMs).clamp(0, 1).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isReviewMode
          ? '復習モード（${widget.mode == 'required' ? '必修' : '一般'}）'
          : (widget.mode == 'required' ? '必修' : '一般・状況設定')),
        actions: [
          TextButton.icon(
            onPressed: _showFinishConfirmDialog,
            icon: const Icon(Icons.done),
            label: const Text('学習終了'),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '問題',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          QuestionSourceBadge(source: question.source),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.stem,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 問題形式に応じた解答UI
              QuestionAnswerWidget(
                question: question,
                enabled: !answered,
                onAnswer: (answer) => _submit(
                  answer: answer,
                  isSkip: false,
                  timeExpired: false,
                ),
              ),
              
              TextButton(
                onPressed: answered
                    ? null
                    : () => _submit(
                          answer: null,
                          isSkip: true,
                          timeExpired: false,
                        ),
                child: const Text('わからない(スキップ)'),
              ),
              if (answered) ...[
                const SizedBox(height: 16),
                _AnswerFeedbackCard(
                  question: question,
                  userAnswer: _userAnswer,
                  wasSkip: lastWasSkip,
                  timeExpired: lastTimeExpired,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    controller.advanceToNextQuestion();
                  },
                  child: const Text('次の問題へ'),
                ),
              ],
              const SizedBox(height: 16),
              Text('自信度(任意)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('自信あり'),
                    selected: confidence == 'high',
                    onSelected: (_) => setState(() => confidence = 'high'),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('自信なし'),
                    selected: confidence == 'low',
                    onSelected: (_) => setState(() => confidence = 'low'),
                  ),
                ],
              ),
              if (question.source?.type == 'past_exam') ...[
                const SizedBox(height: 12),
                Text(
                  '詳細な出典は「その他 > 出典・著作権」をご確認ください。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              _TimerFooter(
                timeProgress: timeProgress,
                remainingSeconds: (remainingMs / 1000).ceil(),
                timeExpired: lastTimeExpired,
                showTimer: _showTimer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerFeedbackCard extends StatelessWidget {
  const _AnswerFeedbackCard({
    required this.question,
    required this.userAnswer,
    required this.wasSkip,
    required this.timeExpired,
  });

  final Question question;
  final dynamic userAnswer;
  final bool wasSkip;
  final bool timeExpired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 正解判定
    final isCorrect = !wasSkip && !timeExpired && question.isCorrect(userAnswer);
    
    String status;
    if (timeExpired) {
      status = '時間の目安を超過';
    } else if (wasSkip) {
      status = 'スキップ';
    } else if (isCorrect) {
      status = '正解';
    } else {
      status = '不正解';
    }
    
    final statusColor = isCorrect
        ? theme.colorScheme.primary
        : (wasSkip || timeExpired
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.error);
    
    final explanationText = question.explainLong?.trim().isNotEmpty == true
        ? question.explainLong!
        : question.explainShort?.trim().isNotEmpty == true
            ? question.explainShort!
            : '解説は準備中です';
    
    // 正解の選択肢インデックスを取得
    List<int> correctIndices = [];
    if (question.format == 'single_choice' && question.answer.value != null) {
      correctIndices = [question.answer.value!];
    } else if (question.format == 'multiple_choice' && question.answer.values != null) {
      correctIndices = question.answer.values!;
    }

    // ユーザーの回答の選択肢インデックスを取得
    List<int> userIndices = [];
    if (!wasSkip && !timeExpired && userAnswer != null) {
      if (question.format == 'single_choice') {
        userIndices = [userAnswer as int];
      } else if (question.format == 'multiple_choice') {
        userIndices = userAnswer as List<int>;
      }
    }
    
    return Card(
      color: theme.colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status,
              style: theme.textTheme.titleMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (timeExpired)
              Text(
                'この結果は記録として扱いません。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

            // ユーザーの回答表示
            if (!wasSkip && !timeExpired && userAnswer != null) ...[
              const SizedBox(height: 8),
              Text(
                'あなたの回答',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (question.format == 'numeric_input')
                Text('$userAnswer${question.answer.unit ?? ''}', style: theme.textTheme.bodyLarge)
              else
                ...userIndices.map((idx) => _buildChoiceBadge(
                  context: context,
                  choiceIndex: idx,
                  choiceText: question.getChoiceText(idx),
                  isCorrect: isCorrect,
                  isUserAnswer: true,
                )),
            ],

            // 正解表示（不正解の場合のみ）
            if (!isCorrect) ...[
              const SizedBox(height: 8),
              Text(
                '正解',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              if (question.format == 'numeric_input')
                Text(
                  '${question.answer.value}${question.answer.unit ?? ''}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                ...correctIndices.map((idx) => _buildChoiceBadge(
                  context: context,
                  choiceIndex: idx,
                  choiceText: question.getChoiceText(idx),
                  isCorrect: true,
                  isUserAnswer: false,
                )),
            ],

            const SizedBox(height: 12),
            Text(
              explanationText,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// 選択肢をバッジ形式で表示するヘルパー
  Widget _buildChoiceBadge({
    required BuildContext context,
    required int choiceIndex,
    required String choiceText,
    required bool isCorrect,
    required bool isUserAnswer,
  }) {
    final theme = Theme.of(context);
    final badgeColor = isCorrect
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    final containerColor = isCorrect
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.errorContainer;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // 選択肢番号バッジ
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: badgeColor,
                width: 2,
              ),
              color: containerColor,
            ),
            child: Center(
              child: Text(
                '$choiceIndex',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCorrect
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 選択肢テキスト
          Expanded(
            child: Text(
              choiceText,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerFooter extends StatelessWidget {
  const _TimerFooter({
    required this.timeProgress,
    required this.remainingSeconds,
    required this.timeExpired,
    required this.showTimer,
  });

  final double timeProgress;
  final int remainingSeconds;
  final bool timeExpired;
  final bool showTimer;

  @override
  Widget build(BuildContext context) {
    if (!showTimer) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final label = timeExpired ? '目安時間に到達' : '1問の目安';
    final subLabel = timeExpired ? 'この時間は参考です' : '時間は参考です';
    final progressColor = timeExpired
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary.withOpacity(0.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelMedium),
            const Spacer(),
            Text(
              'あと$remainingSeconds秒',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: timeProgress,
            minHeight: 4,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(progressColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subLabel,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
