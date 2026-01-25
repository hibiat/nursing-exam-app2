import 'dart:async';

import 'package:flutter/material.dart';

import '../models/question.dart';
import '../repositories/user_settings_repository.dart';
import '../state/study_session_controller.dart';
import '../widgets/score_update_overlay.dart';
import 'study_summary_screen.dart';


class StudyScreen extends StatefulWidget {
  const StudyScreen({
    super.key,
    required this.mode,
    required this.domainId,
    required this.subdomainId,
  });

  final String mode;
  final String domainId;
  final String subdomainId;

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
  String? selectedChoice;
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
        selectedChoice = null;
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

  void _submit({required String? chosen, required bool isSkip, required bool timeExpired}) {
    if (answered) return;
    
    final question = _displayQuestion ?? controller.currentQuestion;
    if (question == null) return;
    
    // 統計を更新
    if (!timeExpired) {
      _totalAnswered++;
      final isCorrect = chosen != null && chosen == question.answer && !isSkip;
      if (isCorrect) {
        _correctCount++;
      }
    }
    
    setState(() {
      answered = true;
      selectedChoice = chosen;
      lastWasSkip = isSkip;
      lastTimeExpired = timeExpired;
      if (timeExpired) {
        remainingMs = 0;
      }
    });
    timer?.cancel();
    controller.submitAnswer(
      chosen: chosen,
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
      if (answered || controller.showOverlay) return;
      setState(() {
        remainingMs = (remainingMs - _timerTickMs).clamp(0, _timeLimitMs);
        elapsedMs = (_timeLimitMs - remainingMs).clamp(0, _timeLimitMs);
      });
      if (remainingMs <= 0 && !answered) {
        _submit(chosen: null, isSkip: false, timeExpired: true);
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
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StudySummaryScreen(
            questionsAnswered: _totalAnswered,
            correctCount: _correctCount,
            skillProgress: controller.latestSkillProgress,
            rank: controller.overallRank,
            lastRank: controller.lastOverallRank,
            overallScoreDelta: controller.overallScore - controller.lastOverallScore,
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
              child: Text('設定の読み込みに失敗しました: ${snapshot.error}'),
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
              Text('読み込みに失敗しました: ${controller.loadError}'),
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
    final isCorrect = answered &&
        !lastWasSkip &&
        !lastTimeExpired &&
        selectedChoice != null &&
        selectedChoice == question.answer;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == 'required' ? '必修' : '一般・状況設定'),
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
                      Text(
                        '問題',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
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
              ...question.choices.map(
                (choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    onPressed: answered
                        ? null
                        : () => _submit(
                              chosen: choice,
                              isSkip: false,
                              timeExpired: false,
                            ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                      backgroundColor: answered
                          ? (choice == question.answer
                              ? Theme.of(context).colorScheme.primaryContainer
                              : (selectedChoice == choice
                                  ? Theme.of(context).colorScheme.errorContainer
                                  : null))
                          : null,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(child: Text(choice)),
                          if (answered && choice == question.answer)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          if (answered &&
                              selectedChoice == choice &&
                              selectedChoice != question.answer)
                            Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.error,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: answered
                    ? null
                    : () => _submit(
                          chosen: null,
                          isSkip: true,
                          timeExpired: false,
                        ),
                child: const Text('わからない(スキップ)'),
              ),
              if (answered) ...[
                const SizedBox(height: 16),
                _AnswerFeedbackCard(
                  isCorrect: isCorrect,
                  wasSkip: lastWasSkip,
                  timeExpired: lastTimeExpired,
                  selectedChoice: selectedChoice,
                  correctAnswer: question.answer,
                  explanation: question.explainLong ?? question.explainShort,
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
              const SizedBox(height: 12),
              _TimerFooter(
                timeProgress: timeProgress,
                remainingSeconds: (remainingMs / 1000).ceil(),
                timeExpired: lastTimeExpired,
                showTimer: _showTimer,
              ),
            ],
          ),
          if (controller.showOverlay)
            ScoreUpdateOverlay(
              rank: controller.overallRank,
              lastRank: controller.lastOverallRank,
              overallScore: controller.overallScore,
              skillProgress: controller.latestSkillProgress,
              showStreakPraise: controller.showStreakPraise,
              streakMessage: controller.streakMessage,
              streakCount: controller.streakCount,
              requiredBorderLabel: null,
              onClose: controller.dismissOverlay,
            ),
        ],
      ),
    );
  }
}

class _AnswerFeedbackCard extends StatelessWidget {
  const _AnswerFeedbackCard({
    required this.isCorrect,
    required this.wasSkip,
    required this.timeExpired,
    required this.selectedChoice,
    required this.correctAnswer,
    required this.explanation,
  });

  final bool isCorrect;
  final bool wasSkip;
  final bool timeExpired;
  final String? selectedChoice;
  final String correctAnswer;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
    final explanationText = explanation?.trim().isNotEmpty == true
        ? explanation!
        : '解説は準備中です';
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
            Text('正解: $correctAnswer'),
            if (selectedChoice != null && !wasSkip && !timeExpired)
              Text('あなたの回答: $selectedChoice'),
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