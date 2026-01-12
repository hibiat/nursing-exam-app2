import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/dummy_questions.dart';
import '../models/attempt.dart';
import '../models/question.dart';
import '../models/question_state.dart';
import '../models/score_engine.dart';
import '../models/skill_state.dart';
import '../repositories/attempt_repository.dart';
import '../repositories/question_state_repository.dart';
import '../repositories/skill_state_repository.dart';
import '../services/auth_service.dart';
import '../services/question_set_service.dart';
import '../services/scheduler.dart';

class StudySessionController extends ChangeNotifier {
  StudySessionController({
    required this.mode,
    required this.domainId,
    required this.subdomainId,
    required this.unitTarget,
    AttemptRepository? attemptRepository,
    QuestionStateRepository? questionStateRepository,
    SkillStateRepository? skillStateRepository,
    QuestionSetService? questionSetService,
  })  : attemptRepository = attemptRepository ?? AttemptRepository(),
        questionStateRepository = questionStateRepository ?? QuestionStateRepository(),
        skillStateRepository = skillStateRepository ?? SkillStateRepository(),
        questionSetService = questionSetService ?? QuestionSetService();

  final String mode;
  final String domainId;
  final String subdomainId;
  final int unitTarget;
  final AttemptRepository attemptRepository;
  final QuestionStateRepository questionStateRepository;
  final SkillStateRepository skillStateRepository;
  final QuestionSetService questionSetService;
  final Scheduler scheduler = const Scheduler();
  final ScoreEngine scoreEngine = ScoreEngine();

  final Map<String, QuestionState> questionStates = {};
  final Map<String, SkillState> skillStates = {};

  final Set<String> answeredQuestionIds = {};
  final Set<String> completedCaseIds = {};

  int unitCount = 0;
  String? currentQuestionId;
  String? lastRank;
  String? currentRank;
  double currentScore = 50;
  bool showOverlay = false;
  bool showStreakPraise = true;
  String? requiredBorderLabel;
  bool isLoading = true;
  String? loadError;
  DateTime? lastUnitCompletedAt;

  List<Question> _questions = [];

  Question? get currentQuestion {
    if (_questions.isEmpty) return null;
    return _questions.firstWhere(
      (q) => q.id == currentQuestionId,
      orElse: () => _questions.first,
    );
  }

  Future<void> start() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final user = await AuthService.ensureSignedIn();
      // ignore: avoid_print
      print('StudySessionController.start signed in uid=${user.uid}');
      // ignore: avoid_print
      print('StudySessionController.start loading questions mode=$mode');
      final loaded = await questionSetService.loadActiveQuestions(mode: mode);
      // ignore: avoid_print
      print('StudySessionController.start loaded count=${loaded.length}');
      _questions = _filterQuestions(loaded);
      // ignore: avoid_print
      print(
        'StudySessionController.start filtered count=${_questions.length} '
        'domainId=$domainId subdomainId=$subdomainId',
      );
      if (_questions.isEmpty) {
        _questions = _filterQuestions(
          dummyQuestions.where((q) => q.mode == mode).toList(),
        );
        // ignore: avoid_print
        print(
          'StudySessionController.start fallback dummy count=${_questions.length} '
          'domainId=$domainId subdomainId=$subdomainId',
        );
      }
    } catch (error) {
      loadError = error.toString();
      // ignore: avoid_print
      print('StudySessionController.start error=$error');
      _questions = _filterQuestions(
        dummyQuestions.where((q) => q.mode == mode).toList(),
      );
    }
    isLoading = false;
    _pickNextQuestion();
    notifyListeners();
  }

  Future<void> submitAnswer({
    required String? chosen,
    required bool isSkip,
    required int responseTimeMs,
    required bool timeExpired,
    String? confidence,
  }) async {
    final question = currentQuestion;
    if (question == null) return;

    final isCorrect = chosen != null && chosen == question.answer && !isSkip && !timeExpired;
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

    SkillState? updatedSkill;
    if (!timeExpired) {
      updatedSkill = SkillState(
        subdomainId: question.subdomainId,
        theta: scoreResult.theta,
        nEff: (skillStates[question.subdomainId]?.nEff ?? 0) + 1,
        lastUpdatedAt: DateTime.now(),
      );
      skillStates[question.subdomainId] = updatedSkill;
    }

    lastRank = currentRank;
    currentRank = scoreResult.rank;
    currentScore = scoreResult.score;

    final now = DateTime.now();
    final previousStability = questionStates[question.id]?.stability ?? 1;
    final updatedState = _updateQuestionState(
      question: question,
      previousStability: previousStability,
      wasLapses: questionStates[question.id]?.lapses ?? 0,
      isCorrect: isCorrect,
      now: now,
    );
    questionStates[question.id] = updatedState;

    final attempt = Attempt(
      id: '${question.id}_${now.millisecondsSinceEpoch}',
      questionId: question.id,
      mode: question.mode,
      domainId: question.domainId,
      subdomainId: question.subdomainId,
      chosen: isSkip || timeExpired ? null : chosen,
      isCorrect: isCorrect,
      isSkip: isSkip,
      confidence: confidence,
      responseTimeMs: responseTimeMs,
      timeExpired: timeExpired,
      answeredAt: now,
      difficulty: question.difficulty,
    );

    await attemptRepository.saveAttempt(attempt);
    await questionStateRepository.saveQuestionState(updatedState);
    if (updatedSkill != null) {
      await skillStateRepository.saveSkillState(updatedSkill);
    }

    _updateUnitProgress(question);

    _pickNextQuestion();
    notifyListeners();
  }

  void dismissOverlay() {
    showOverlay = false;
    showStreakPraise = false;
    requiredBorderLabel = null;
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

  List<Question> _filterQuestions(List<Question> source) {
    return source
        .where((question) => question.domainId == domainId)
        .where((question) => question.subdomainId == subdomainId)
        .toList();
  }

  QuestionState _updateQuestionState({
    required Question question,
    required double previousStability,
    required int wasLapses,
    required bool isCorrect,
    required DateTime now,
  }) {
    final updatedLapses = wasLapses + (isCorrect ? 0 : 1);
    final stabilityDelta = isCorrect ? 0.6 : -0.4;
    final nextStability = max(1.0, previousStability + stabilityDelta);
    final intervalDays = max(2, nextStability.round());
    final dueAt = _minDueAt(now, intervalDays);
    return QuestionState(
      questionId: question.id,
      dueAt: dueAt,
      stability: nextStability,
      lapses: max(updatedLapses, 0),
      lastSeenAt: now,
    );
  }

  DateTime _minDueAt(DateTime now, int intervalDays) {
    final base = DateTime(now.year, now.month, now.day).add(const Duration(days: 2));
    final interval = DateTime(now.year, now.month, now.day).add(Duration(days: intervalDays));
    return interval.isBefore(base) ? base : interval;
  }

  void _updateUnitProgress(Question question) {
    if (question.caseId != null) {
      answeredQuestionIds.add(question.id);
      final caseId = question.caseId!;
      final caseQuestions = _questions.where((q) => q.caseId == caseId).toList();
      final allAnswered = caseQuestions.isNotEmpty &&
          caseQuestions.every((q) => answeredQuestionIds.contains(q.id));
      if (allAnswered && !completedCaseIds.contains(caseId)) {
        completedCaseIds.add(caseId);
        _triggerUnitComplete();
      }
      return;
    }

    unitCount += 1;
    if (unitCount >= unitTarget) {
      unitCount = 0;
      _triggerUnitComplete();
    }
  }

  void _triggerUnitComplete() {
    showOverlay = true;
    final now = DateTime.now();
    final isFirstToday = lastUnitCompletedAt == null ||
        lastUnitCompletedAt!.year != now.year ||
        lastUnitCompletedAt!.month != now.month ||
        lastUnitCompletedAt!.day != now.day;
    showStreakPraise = isFirstToday;
    if (mode == 'required') {
      requiredBorderLabel = _requiredBorderLabel(currentScore);
    } else {
      requiredBorderLabel = null;
    }
    lastUnitCompletedAt = now;
  }

  String _requiredBorderLabel(double score) {
    if (score >= 80) return '余裕';
    if (score >= 70) return '安定';
    if (score >= 60) return '注意';
    return '危険';
  }
}
