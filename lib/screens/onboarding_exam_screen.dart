import 'package:flutter/material.dart';

import '../state/onboarding_exam_controller.dart';

class OnboardingExamScreen extends StatefulWidget {
  const OnboardingExamScreen({super.key});

  @override
  State<OnboardingExamScreen> createState() => _OnboardingExamScreenState();
}

class _OnboardingExamScreenState extends State<OnboardingExamScreen> {
  late final OnboardingExamController controller;
  final Set<int> _selectedChoices = <int>{};

  @override
  void initState() {
    super.initState();
    controller = OnboardingExamController();
    controller.addListener(_onUpdate);
    controller.start();
  }

  @override
  void dispose() {
    controller.removeListener(_onUpdate);
    controller.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _submitCurrent() {
    final question = controller.currentQuestion;
    if (question == null) return;
    if (question.answer.type == 'multiple') {
      controller.submitAnswer(userAnswer: _selectedChoices.toList(), isSkip: false);
      _selectedChoices.clear();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (controller.loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ショート模試')),
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
    if (controller.isCompleted) {
      return Scaffold(
        appBar: AppBar(title: const Text('ショート模試')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ショート模試が完了しました！'),
              const SizedBox(height: 8),
              Text(
                '推定スコア ${controller.summaryScore.toStringAsFixed(0)} '
                '（ランク ${controller.summaryRank}）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ホームに戻る'),
              ),
            ],
          ),
        ),
      );
    }

    final question = controller.currentQuestion;
    if (question == null) {
      return const Scaffold(body: Center(child: Text('問題がありません')));
    }

    final progress = (controller.currentIndex + 1) / controller.totalQuestions;

    return Scaffold(
      appBar: AppBar(title: const Text('ショート模試')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'ショート模試 ${controller.currentIndex + 1} / ${controller.totalQuestions}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, minHeight: 6),
          const SizedBox(height: 16),
          Text(
            question.stem,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...question.choices.map(
            (choice) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: question.answer.type == 'multiple'
                  ? CheckboxListTile(
                      value: _selectedChoices.contains(choice.index),
                      title: Text(choice.text),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedChoices.add(choice.index);
                          } else {
                            _selectedChoices.remove(choice.index);
                          }
                        });
                      },
                    )
                  : OutlinedButton(
                      onPressed: () => controller.submitAnswer(
                        userAnswer: choice.index,
                        isSkip: false,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(choice.text),
                      ),
                    ),
            ),
          ),
          if (question.answer.type == 'multiple')
            FilledButton(
              onPressed: _selectedChoices.isEmpty ? null : _submitCurrent,
              child: const Text('この回答で次へ'),
            ),
          if (question.answer.type == 'multiple')
            const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _selectedChoices.clear();
              controller.submitAnswer(userAnswer: null, isSkip: true);
            },
            child: const Text('わからない（スキップ）'),
          ),
        ],
      ),
    );
  }
}
