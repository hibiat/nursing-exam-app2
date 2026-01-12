import 'dart:async';

import 'package:flutter/material.dart';

import '../repositories/user_settings_repository.dart';
import '../state/study_session_controller.dart';
import '../widgets/score_update_overlay.dart';

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
  static const int _timerTickMs = 1000;
  int _timeLimitMs = UserSettingsRepository.defaultTimeLimitSeconds * 1000;

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
    remainingMs = _timeLimitMs;
    await controller.start();
    _startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.removeListener(_onUpdate);
    controller.dispose();
    super.dispose();
  }

  void _onUpdate() {
    setState(() {
      answered = false;
      selectedChoice = null;
      confidence = null;
      elapsedMs = 0;
      remainingMs = _timeLimitMs;
    });
  }

  void _submit({required String? chosen, required bool isSkip, required bool timeExpired}) {
    if (answered) return;
    setState(() {
      answered = true;
      selectedChoice = chosen;
    });
    controller.submitAnswer(
      chosen: chosen,
      isSkip: isSkip,
      responseTimeMs: elapsedMs,
      timeExpired: timeExpired,
      confidence: confidence,
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

    final question = controller.currentQuestion;
    if (question == null) {
      return const Scaffold(
        body: Center(child: Text('問題がありません')),
      );
    }

    final timeProgress = (remainingMs / _timeLimitMs).clamp(0, 1).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == 'required' ? '必修' : '一般・状況設定'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                question.stem,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: timeProgress,
                minHeight: 6,
              ),
              const SizedBox(height: 8),
              Text('残り時間: ${(remainingMs / 1000).ceil()}秒'),
              const SizedBox(height: 24),
              ...question.choices.map(
                (choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    onPressed: () => _submit(
                      chosen: choice,
                      isSkip: false,
                      timeExpired: false,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(choice),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _submit(
                  chosen: null,
                  isSkip: true,
                  timeExpired: false,
                ),
                child: const Text('わからない（スキップ）'),
              ),
              const SizedBox(height: 16),
              Text('自信度（任意）', style: Theme.of(context).textTheme.titleSmall),
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
              requiredBorderLabel: controller.requiredBorderLabel,
              onClose: controller.dismissOverlay,
            ),
        ],
      ),
    );
  }
}
