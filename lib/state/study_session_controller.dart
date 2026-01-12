import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/dummy_questions.dart';
import '../models/attempt.dart';
import '../models/question.dart';
import '../models/question_state.dart';
import '../models/score_engine.dart';
import '../models/skill_progress.dart';
import '../models/skill_state.dart';
import '../models/streak_state.dart';
import '../repositories/attempt_repository.dart';
import '../repositories/question_state_repository.dart';
import '../repositories/skill_state_repository.dart';
import '../repositories/streak_state_repository.dart';
import '../services/auth_service.dart';
import '../services/question_set_service.dart';
import '../services/scheduler.dart';
import '../services/taxonomy_service.dart';

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
    StreakStateRepository? streakStateRepository,
  })  : attemptRepository = attemptRepository ?? AttemptRepository(),
        questionStateRepository = questionStateRepository ?? QuestionStateRepository(),
        skillStateRepository = skillStateRepository ?? SkillStateRepository(),
        questionSetService = questionSetService ?? QuestionSetService(),
        streakStateRepository = streakStateRepository ?? StreakStateRepository();

  final String mode;
  final String domainId;
  final String subdomainId;
  final int unitTarget;
  final AttemptRepository attemptRepository;
  final QuestionStateRepository questionStateRepository;
  final SkillStateRepository skillStateRepository;
  final QuestionSetService questionSetService;
  final StreakStateRepository streakStateRepository;
  final Scheduler scheduler = const Scheduler();
  final ScoreEngine scoreEngine = ScoreEngine();
  final TaxonomyService taxonomyService = TaxonomyService();

  final Map<String, QuestionState> questionStates = {};
  final Map<String, SkillState> skillStates = {};

  final Set<String> answeredQuestionIds = {};
  final Set<String> completedCaseIds = {};

  final Map<String, String> skillLabels = {};
  List<SkillProgress> latestSkillProgress = [];
  final Map<String, double> lastSkillScores = {};

  int unitCount = 0;
  String? currentQuestionId;
  String? lastOverallRank;
  String? overallRank;
  double lastOverallScore = 50;
  double overallScore = 50;
  bool showOverlay = false;
  bool showStreakPraise = true;
  String? requiredBorderLabel;
  String? streakMessage;
  int streakCount = 0;
  bool isLoading = true;
  String? loadError;
  DateTime? lastUnitCompletedAt;
  DateTime? lastStudyDate;

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
      await _loadSkillScopes();
      await _loadSkillStates();
      await _loadQuestionStates();
      await _loadStreakState();
      _snapshotSkillScores();
      _refreshSkillProgressSnapshot();
      _refreshOverallScore();
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
    bool advanceAfterSubmit = true,
  }) async {
    final question = currentQuestion;
    if (question == null) return;

    try {
      final isCorrect = chosen != null && chosen == question.answer && !isSkip && !timeExpired;
      final wasState = questionStates[question.id];
      final wasIncorrectBefore = (wasState?.lapses ?? 0) > 0;
      final wasMostlyCorrect = (wasState?.lapses ?? 0) == 0 && wasState != null;
      final skillScopeId = _skillScopeId(question);

      final scoreResult = scoreEngine.updateTheta(
        theta: skillStates[skillScopeId]?.theta ?? 0,
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
          skillId: skillScopeId,
          theta: scoreResult.theta,
          nEff: (skillStates[skillScopeId]?.nEff ?? 0) + 1,
          lastUpdatedAt: DateTime.now(),
        );
        skillStates[skillScopeId] = updatedSkill;
      }

      _refreshOverallScore();

      final now = DateTime.now();
      final previousStability = questionStates[question.id]?.stability ?? 1;
      final updatedState = _updateQuestionState(
        question: question,
        previousStability: previousStability,
        wasLapses: questionStates[question.id]?.lapses ?? 0,
        isCorrect: isCorrect,
        timeExpired: timeExpired,
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

      try {
        await attemptRepository.saveAttempt(attempt);
        await questionStateRepository.saveQuestionState(updatedState);
        if (updatedSkill != null) {
          await skillStateRepository.saveSkillState(updatedSkill);
        }
      } catch (error) {
        // ignore: avoid_print
        print('StudySessionController.submitAnswer save error=$error');
      }
    } finally {
      await _updateUnitProgress(question);
      if (advanceAfterSubmit) {
        _pickNextQuestion();
      }
      notifyListeners();
    }
  }

  void dismissOverlay() {
    showOverlay = false;
    showStreakPraise = false;
    requiredBorderLabel = null;
    streakMessage = null;
    notifyListeners();
  }

  void _pickNextQuestion() {
    final previousId = currentQuestionId;
    final nextId = scheduler.selectNextQuestion(
      candidates: _questions,
      questionStates: questionStates,
      skillStates: skillStates,
      now: DateTime.now(),
      skillScopeResolver: _skillScopeId,
    );
    if (previousId != null && nextId == previousId && _questions.length > 1) {
      final remaining = _questions.where((q) => q.id != previousId).toList();
      currentQuestionId = scheduler.selectNextQuestion(
            candidates: remaining,
            questionStates: questionStates,
            skillStates: skillStates,
            now: DateTime.now(),
            skillScopeResolver: _skillScopeId,
          ) ??
          nextId;
      return;
    }
    currentQuestionId = nextId ?? (_questions.isNotEmpty ? _questions.first.id : null);
  }

  void advanceToNextQuestion() {
    _pickNextQuestion();
    notifyListeners();
  }

  List<Question> _filterQuestions(List<Question> source) {
    return source
        .where((question) => question.domainId == domainId)
        .where((question) => subdomainId == 'all' || question.subdomainId == subdomainId)
        .toList();
  }

  QuestionState _updateQuestionState({
    required Question question,
    required double previousStability,
    required int wasLapses,
    required bool isCorrect,
    required bool timeExpired,
    required DateTime now,
  }) {
    final isNeutral = timeExpired;
    final updatedLapses = wasLapses + (isCorrect || isNeutral ? 0 : 1);
    final stabilityDelta = isNeutral ? 0.0 : (isCorrect ? 0.6 : -0.4);
    final nextStability = max(1.0, previousStability + stabilityDelta);
    final intervalDays = max(2, nextStability.round());
    final dueAt = _minDueAt(now, intervalDays);
    return QuestionState(
      questionId: question.id,
      mode: question.mode,
      domainId: question.domainId,
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

  Future<void> _updateUnitProgress(Question question) async {
    if (question.caseId != null) {
      answeredQuestionIds.add(question.id);
      final caseId = question.caseId!;
      final caseQuestions = _questions.where((q) => q.caseId == caseId).toList();
      final allAnswered = caseQuestions.isNotEmpty &&
          caseQuestions.every((q) => answeredQuestionIds.contains(q.id));
      if (allAnswered && !completedCaseIds.contains(caseId)) {
        completedCaseIds.add(caseId);
        await _triggerUnitComplete();
      }
      return;
    }

    unitCount += 1;
    if (unitCount >= unitTarget) {
      unitCount = 0;
      await _triggerUnitComplete();
    }
  }

  Future<void> _triggerUnitComplete() async {
    final now = DateTime.now();
    final isFirstToday = lastUnitCompletedAt == null ||
        lastUnitCompletedAt!.year != now.year ||
        lastUnitCompletedAt!.month != now.month ||
        lastUnitCompletedAt!.day != now.day;
    showStreakPraise = isFirstToday;
    if (isFirstToday) {
      final updatedStreak = _calculateStreak(now);
      streakCount = updatedStreak.currentStreak;
      streakMessage = _buildStreakMessage(streakCount);
      await streakStateRepository.saveStreakState(updatedStreak);
      lastUnitCompletedAt = updatedStreak.lastUnitCompletedAt;
      lastStudyDate = updatedStreak.lastStudyDate;
    } else {
      streakMessage = null;
    }
    if (mode == 'required') {
      requiredBorderLabel = _requiredBorderLabel(overallScore);
    } else {
      requiredBorderLabel = null;
    }
    // Before/after差分はここで確定:
    // - lastSkillScores(前回) -> SkillProgress.previousScore
    // - skillStates(今回) -> SkillProgress.currentScore
    // overlayにはlatestSkillProgressとして渡す。
    _refreshSkillProgressSnapshot();
    _snapshotSkillScores();
    await Future.delayed(const Duration(milliseconds: 320));
    showOverlay = true;
    notifyListeners();
  }

  String _requiredBorderLabel(double score) {
    if (score >= 80) return '余裕';
    if (score >= 70) return '安定';
    if (score >= 60) return '注意';
    return '危険';
  }

  String _skillScopeId(Question question) {
    return mode == 'required' ? question.subdomainId : question.domainId;
  }

  Future<void> _loadSkillScopes() async {
    final asset = mode == 'required'
        ? 'assets/taxonomy_required.json'
        : 'assets/taxonomy_general.json';
    final domains = await taxonomyService.loadDomains(asset);
    if (domains.isEmpty) {
      return;
    }
    skillLabels.clear();
    if (mode == 'required') {
      for (final subdomain in domains.first.subdomains) {
        skillLabels[subdomain.id] = subdomain.name;
      }
      return;
    }
    for (final domain in domains) {
      skillLabels[domain.id] = domain.name;
    }
  }

  Future<void> _loadSkillStates() async {
    if (skillLabels.isEmpty) return;
    final stored = await skillStateRepository.fetchSkillStates(skillLabels.keys);
    skillStates
      ..clear()
      ..addAll(stored);
  }

  Future<void> _loadQuestionStates() async {
    final stored = await questionStateRepository.fetchQuestionStates(
      mode: mode,
      domainId: domainId,
    );
    questionStates
      ..clear()
      ..addEntries(stored.map((state) => MapEntry(state.questionId, state)));
  }

  Future<void> _loadStreakState() async {
    final stored = await streakStateRepository.fetchStreakState();
    lastUnitCompletedAt = stored?.lastUnitCompletedAt;
    lastStudyDate = stored?.lastStudyDate;
    if (stored != null) {
      streakCount = stored.currentStreak;
    }
  }

  void _refreshOverallScore() {
    if (skillLabels.isEmpty) {
      overallScore = 50;
      overallRank = scoreEngine.rankFromScore(overallScore);
      return;
    }
    final scores = skillLabels.keys
        .map((skillId) => scoreEngine.scoreFromTheta(skillStates[skillId]?.theta ?? 0))
        .toList();
    overallScore = scores.reduce((a, b) => a + b) / scores.length;
    overallRank = scoreEngine.rankFromScore(overallScore);
  }

  void _refreshSkillProgressSnapshot() {
    if (skillLabels.isEmpty) {
      latestSkillProgress = [];
      lastOverallScore = overallScore;
      lastOverallRank = overallRank;
      return;
    }
    final previousScores = skillLabels.keys
        .map((skillId) => lastSkillScores[skillId] ?? 50)
        .toList();
    lastOverallScore = previousScores.reduce((a, b) => a + b) / previousScores.length;
    lastOverallRank = scoreEngine.rankFromScore(lastOverallScore);
    latestSkillProgress = skillLabels.entries
        .map(
          (entry) => SkillProgress(
            skillId: entry.key,
            label: entry.value,
            previousScore: lastSkillScores[entry.key] ??
                scoreEngine.scoreFromTheta(skillStates[entry.key]?.theta ?? 0),
            currentScore: scoreEngine.scoreFromTheta(skillStates[entry.key]?.theta ?? 0),
          ),
        )
        .toList();
  }

  void _snapshotSkillScores() {
    lastSkillScores
      ..clear()
      ..addEntries(
        skillLabels.keys.map(
          (skillId) => MapEntry(
            skillId,
            scoreEngine.scoreFromTheta(skillStates[skillId]?.theta ?? 0),
          ),
        ),
      );
  }

  StreakState _calculateStreak(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final lastStudyDate = this.lastStudyDate ??
        DateTime(
          lastUnitCompletedAt?.year ?? 1970,
          lastUnitCompletedAt?.month ?? 1,
          lastUnitCompletedAt?.day ?? 1,
        );
    final yesterday = today.subtract(const Duration(days: 1));
    int nextStreak;
    if (lastUnitCompletedAt == null) {
      nextStreak = 1;
    } else if (lastStudyDate == today) {
      nextStreak = streakCount;
    } else if (lastStudyDate == yesterday) {
      nextStreak = streakCount + 1;
    } else {
      nextStreak = 1;
    }
    return StreakState(
      currentStreak: nextStreak,
      lastStudyDate: today,
      lastUnitCompletedAt: now,
    );
  }

  String _buildStreakMessage(int streak) {
    if (streak >= 5) return '連続$streak日達成！この調子でいきましょう！';
    if (streak >= 3) return '連続$streak日目！すごいです！';
    return '連続学習$streak日目！いいスタートです！';
  }
}
