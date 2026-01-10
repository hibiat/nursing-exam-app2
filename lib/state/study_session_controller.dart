import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/dummy_questions.dart';
import '../models/attempt.dart';
import '../models/question.dart';
import '../models/question_state.dart';
import '../models/scheduler.dart';
import '../models/score_engine.dart';
import '../models/skill_state.dart';
import '../repositories/attempt_repository.dart';
import '../repositories/question_state_repository.dart';
import '../repositories/skill_state_repository.dart';

class StudySessionController extends ChangeNotifier {
  StudySessionController({
    required this.mode,
    required this.unitTarget,
    this.attemptRepository,
    this.questionStateRepository,
    this.skillStateRepository,
  });

  final String mode;
  final int unitTarget;
  final AttemptRepository? attemptRepository;
  final QuestionStateRepository? questionStateRepository;
  final SkillStateRepository? skillStateRepository;
  final Scheduler scheduler = const Scheduler();
  final ScoreEngine scoreEngine = ScoreEngine();

  final Map<String, QuestionState> questionStates = {};
  final Map<String, SkillState> skillStates = {};

  int unitCount = 0;
  String? currentQuestionId;
  String? lastRank;
  String? currentRank;
  double currentScore = 50;
  bool showOverlay = false;
  bool showStreakPraise = true;
  bool showRequiredBorder = true;

  List<Question> get _questions => dummyQuestions.where((q) => q.mode == mode).toList();

  Question? get currentQuestion => _questions.firstWhere(
        (q) => q.id == currentQuestionId,
        orElse: () => _questions.first,
      );

  void start() {
    _pickNextQuestion();
  }

  Future<void> submitAnswer({
    required String chosen,
    required bool isSkip,
    required int responseTimeMs,
    required bool timeExpired,
    String? confidence,
  }) async {
    final question = currentQuestion;
    if (question == null) return;

    final isCorrect = chosen == question.answer && !isSkip;
    final wasState = questionStates[question.id];
    final wasIncorrectBefore = (wasState?.lapses ?? 0) > 0;
    final wasMostlyCorrect = (wasState?.lapses ?? 0) == 0 && wasState != null;

    final scoreResult = scoreEngine.updateTheta(
      theta: skillStates[question.subdomainId]?.theta ?? 0,
      isCorrect: isCorrect,
      isSkip: isSkip,
      timeExpired: timeExpired,
      wasIncorrectBefore: wasIncorrectBefore,
      wasMostlyCorrect: wasMostlyCorrect,
      confidence: confidence,
      difficulty: question.difficulty,
    );

    final updatedSkill = SkillState(
      subdomainId: question.subdomainId,
      theta: scoreResult.theta,
      nEff: (skillStates[question.subdomainId]?.nEff ?? 0) + 1,
      lastUpdatedAt: DateTime.now(),
    );
    skillStates[question.subdomainId] = updatedSkill;

    lastRank = currentRank;
    currentRank = scoreResult.rank;
    currentScore = scoreResult.score;

    final now = DateTime.now();
    final dueAt = _minDueAt(now);
    final lapses = (questionStates[question.id]?.lapses ?? 0) + (isCorrect ? 0 : 1);

    final updatedState = QuestionState(
      questionId: question.id,
      dueAt: dueAt,
      stability: (questionStates[question.id]?.stability ?? 1) + (isCorrect ? 0.5 : -0.2),
      lapses: max(lapses, 0),
      lastSeenAt: now,
    );
    questionStates[question.id] = updatedState;

    final attempt = Attempt(
      id: '${question.id}_${now.millisecondsSinceEpoch}',
      questionId: question.id,
      mode: question.mode,
      domainId: question.domainId,
      subdomainId: question.subdomainId,
      chosen: chosen,
      isCorrect: isCorrect,
      isSkip: isSkip,
      confidence: confidence,
      responseTimeMs: responseTimeMs,
      timeExpired: timeExpired,
      answeredAt: now,
      difficulty: question.difficulty,
    );

    await attemptRepository?.saveAttempt(attempt);
    await questionStateRepository?.saveQuestionState(updatedState);
    await skillStateRepository?.saveSkillState(updatedSkill);

    unitCount += 1;
    if (unitCount >= unitTarget) {
      showOverlay = true;
      unitCount = 0;
    }

    _pickNextQuestion();
    notifyListeners();
  }

  void dismissOverlay() {
    showOverlay = false;
    showStreakPraise = false;
    showRequiredBorder = false;
    notifyListeners();
  }

  void _pickNextQuestion() {
    currentQuestionId = scheduler.selectNextQuestion(
          candidates: _questions,
          questionStates: questionStates,
          skillStates: skillStates,
          now: DateTime.now(),
        ) ??
        (_questions.isNotEmpty ? _questions.first.id : null);
  }

  DateTime _minDueAt(DateTime now) {
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 2));
  }
}
