import 'dart:async';

import 'package:flutter/material.dart';

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
  Timer? timer;
  int elapsedMs = 0;
  bool answered = false;
  String? selectedChoice;
  String? confidence;

  @override
  void initState() {
    super.initState();
    controller = StudySessionController(
      mode: widget.mode,
      unitTarget: 5,
    );
    controller.addListener(_onUpdate);
    controller.start();
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!answered) {
        setState(() {
          elapsedMs += 100;
        });
      }
    });
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
    });
  }

  void _submit({required String chosen, required bool isSkip}) {
    if (answered) return;
    setState(() {
      answered = true;
      selectedChoice = chosen;
    });
    controller.submitAnswer(
      chosen: chosen,
      isSkip: isSkip,
      responseTimeMs: elapsedMs,
      timeExpired: false,
      confidence: confidence,
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = controller.currentQuestion;
    if (question == null) {
      return const Scaffold(
        body: Center(child: Text('問題がありません')),
      );
    }

    final timeProgress = (elapsedMs / 15000).clamp(0, 1).toDouble();

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
              Text('解答時間: ${(elapsedMs / 1000).toStringAsFixed(1)}秒'),
              const SizedBox(height: 24),
              ...question.choices.map(
                (choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    onPressed: () => _submit(chosen: choice, isSkip: false),
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
                onPressed: () => _submit(chosen: 'skip', isSkip: true),
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
              rank: controller.currentRank,
              lastRank: controller.lastRank,
              subdomainScore: controller.currentScore,
              showStreakPraise: controller.showStreakPraise,
              showRequiredBorder: widget.mode == 'required' && controller.showRequiredBorder,
              onClose: controller.dismissOverlay,
            ),
        ],
      ),
    );
  }
}
