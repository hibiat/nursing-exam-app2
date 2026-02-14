import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/user_score_service.dart';
import '../state/onboarding_exam_controller.dart';
import '../widgets/question_answer_widget.dart';

class OnboardingExamScreen extends StatefulWidget {
  const OnboardingExamScreen({super.key});

  @override
  State<OnboardingExamScreen> createState() => _OnboardingExamScreenState();
}

class _OnboardingExamScreenState extends State<OnboardingExamScreen> {
  late final OnboardingExamController controller;

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
        body: FutureBuilder<PassingPredictionData>(
          future: UserScoreService().getPredictionData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // エラー時の値
            final requiredScore = snapshot.hasData ? snapshot.data!.requiredScore : controller.summaryScore;
            final requiredRank = snapshot.hasData ? snapshot.data!.requiredRank : controller.summaryRank;
            final generalScore = snapshot.hasData ? snapshot.data!.generalScore : controller.summaryScore * 5;
            final generalRank = snapshot.hasData ? snapshot.data!.generalRank : controller.summaryRank;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.celebration,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ショート模試が完了しました！',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '現在の推定スコア',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    '必修',
                                    style: Theme.of(context).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${requiredScore.toStringAsFixed(1)}点',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '/ 50点',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getRankColor(requiredRank),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'ランク$requiredRank',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    '一般・状況',
                                    style: Theme.of(context).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${generalScore.toStringAsFixed(1)}点',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '/ 250点',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getRankColor(generalRank),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'ランク$generalRank',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('ホームに戻る'),
                    ),
                  ],
                ),
              ),
            );
          },
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
          const SizedBox(height: 24),
          QuestionAnswerWidget(
            question: question,
            enabled: true,
            onAnswer: (answer) {
              controller.submitAnswer(
                userAnswer: answer,
                isSkip: false,
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => controller.submitAnswer(
              userAnswer: null,
              isSkip: true,
            ),
            child: const Text('わからない（スキップ）'),
          ),
        ],
      ),
    );
  }

  /// ランクの色を返す（合格基準画面と同じ色を使用）
  Color _getRankColor(String rank) {
    switch (rank) {
      case 'S':
      case 'A':
        return AppColors.success; // 緑（高得点域・安定域）
      case 'B':
        return AppColors.primary; // 青（合格ライン域）
      case 'C':
        return AppColors.warning; // 黄色（要注意域）
      case 'D':
        return AppColors.scoreDown; // グレー（基礎固め域）
      default:
        return AppColors.textSecondary;
    }
  }
}
