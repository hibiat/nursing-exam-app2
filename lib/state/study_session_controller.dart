import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/attempt.dart';
import '../models/question.dart';
import '../models/question_state.dart';
import '../models/skill_progress.dart';
import '../models/skill_state.dart';
import '../models/streak_state.dart';
import '../repositories/attempt_repository.dart';
import '../repositories/question_state_repository.dart';
import '../repositories/skill_state_repository.dart';
import '../repositories/streak_state_repository.dart';
import '../services/auth_service.dart';
import '../services/question_set_service.dart';
import '../services/review_scheduler.dart';
import '../services/scheduler.dart';
import '../models/score_engine.dart';
import '../services/score_snapshot_service.dart';
import '../services/taxonomy_service.dart';

class StudySessionController extends ChangeNotifier {
  StudySessionController({
    required this.mode,
    required this.domainId,
    required this.subdomainId,
    required this.unitTarget,
    this.isRecommendedMode = false,
    this.isReviewMode = false,
    AttemptRepository? attemptRepository,
    QuestionStateRepository? questionStateRepository,
    SkillStateRepository? skillStateRepository,
    QuestionSetService? questionSetService,
    StreakStateRepository? streakStateRepository,
    ScoreSnapshotService? scoreSnapshotService,
  })  : attemptRepository = attemptRepository ?? AttemptRepository(),
        questionStateRepository = questionStateRepository ?? QuestionStateRepository(),
        skillStateRepository = skillStateRepository ?? SkillStateRepository(),
        questionSetService = questionSetService ?? QuestionSetService(),
        streakStateRepository = streakStateRepository ?? StreakStateRepository(),
        scoreSnapshotService = scoreSnapshotService ?? ScoreSnapshotService(),
        reviewScheduler = const ReviewScheduler();

  final String mode;
  final String domainId;
  final String subdomainId;
  final int unitTarget;
  final bool isRecommendedMode;
  final bool isReviewMode;
  final AttemptRepository attemptRepository;
  final QuestionStateRepository questionStateRepository;
  final SkillStateRepository skillStateRepository;
  final QuestionSetService questionSetService;
  final StreakStateRepository streakStateRepository;
  final ScoreSnapshotService scoreSnapshotService;
  final Scheduler scheduler = const Scheduler();
  final ReviewScheduler reviewScheduler;
  final ScoreEngine scoreEngine = ScoreEngine();
  final TaxonomyService taxonomyService = TaxonomyService();

  final Map<String, QuestionState> questionStates = {};
  final Map<String, SkillState> skillStates = {};
  final Map<String, Attempt> lastAttempts = {}; // 復習モード用：全期間の解答履歴
  final Set<String> answeredQuestionIds = {};
  final Set<String> completedCaseIds = {};
  final Map<String, String> skillLabels = {};

  List<SkillProgress> latestSkillProgress = [];
  final Map<String, double> lastSkillScores = {};

  int unitCount = 0;
  String? currentQuestionId;
  String? lastOverallRank;
  String? overallRank;
  double lastOverallScore = 40; // 必修の合格ライン
  double overallScore = 40;
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
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('ログインが必要です');
      }
      final loaded = await questionSetService.loadActiveQuestions(mode: mode);

      if (loaded.isEmpty) {
        throw Exception(
          'Firebaseから問題を読み込めませんでした。\n'
          '以下を確認してください:\n'
          '1. Firestore: question_sets/v1/metadata/$mode が存在し、active=true\n'
          '2. Storage: question_sets/v1/$mode.jsonl が存在\n'
          '3. Firestore/Storage Rulesで読み取りが許可されている',
        );
      }

      _questions = _filterQuestions(loaded);

      if (_questions.isEmpty) {
        throw Exception(
          'フィルタリング後の問題が0件です。\n'
          'mode=$mode, domainId=$domainId, subdomainId=$subdomainId\n'
          '読み込んだ問題数: ${loaded.length}問\n'
          '問題のdomain_idがTaxonomyと一致しているか確認してください。',
        );
      }

      await _loadSkillScopes();
      await _loadSkillStates();
      await _loadQuestionStates();
      await _loadStreakState();

      // 復習モードの場合、全期間の解答履歴を読み込む
      if (isReviewMode) {
        await _loadLastAttempts();
        await _initializeMissingStatesForReview();
      }

      _snapshotSkillScores();
      _refreshSkillProgressSnapshot();
      _refreshOverallScore();
    } catch (error) {
      print('❌ エラー発生: $error');
      loadError = error.toString();
    }

    isLoading = false;
    _pickNextQuestion();
    notifyListeners();
  }

  /// 復習モード用：全期間の解答履歴を読み込む
  Future<void> _loadLastAttempts() async {
    // 十分に古い日付から現在まで
    final attempts = await attemptRepository.fetchAttemptsByDateRange(
      DateTime(2020, 1, 1),
      DateTime.now(),
    );

    lastAttempts.clear();
    for (final attempt in attempts) {
      // 各問題の最新の解答のみを保持
      final existing = lastAttempts[attempt.questionId];
      if (existing == null || attempt.answeredAt.isAfter(existing.answeredAt)) {
        lastAttempts[attempt.questionId] = attempt;
      }
    }
  }

  /// 復習モード用：AttemptがあるのにquestionStateがない問題の状態を初期化
  Future<void> _initializeMissingStatesForReview() async {
    print('🔧 Initializing missing states for review mode...');
    final now = DateTime.now();
    int initializedCount = 0;

    for (final entry in lastAttempts.entries) {
      final questionId = entry.key;
      final lastAttempt = entry.value;

      // すでにquestionStateが存在する場合はスキップ
      if (questionStates.containsKey(questionId)) continue;

      // 対応するQuestionを探す
      final question = _questions.firstWhere(
        (q) => q.id == questionId,
        orElse: () => _questions.first,
      );

      // デフォルトのQuestionStateを作成
      final defaultState = QuestionState(
        questionId: questionId,
        mode: question.mode,
        domainId: question.domainId,
        dueAt: now, // すぐに復習可能
        stability: 2.0, // デフォルト値
        lapses: lastAttempt.isCorrect ? 0 : 1, // 最新が不正解ならlapses=1
        lastSeenAt: lastAttempt.answeredAt,
      );

      questionStates[questionId] = defaultState;
      initializedCount++;
    }

    print('🔧 Initialized $initializedCount missing states');
  }

  Future<void> submitAnswer({
    required dynamic userAnswer,
    required bool isSkip,
    required int responseTimeMs,
    required bool timeExpired,
    String? confidence,
    bool advanceAfterSubmit = true,
  }) async {
    final question = currentQuestion;
    if (question == null) return;

    try {
      final isCorrect = !isSkip && !timeExpired && question.isCorrect(userAnswer);
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
        final prevNEff = skillStates[skillScopeId]?.nEff ?? 0;
        final updatedNEff = prevNEff + (isCorrect ? 1.0 : 0.5);
        updatedSkill = SkillState(
          skillId: skillScopeId,
          theta: scoreResult.theta,
          nEff: updatedNEff,
          lastUpdatedAt: DateTime.now(),
        );
        skillStates[skillScopeId] = updatedSkill;
        await skillStateRepository.saveSkillState(updatedSkill);
      }

      final now = DateTime.now();
      final previousStability = questionStates[question.id]?.stability ?? 2.0;
      final wasLapses = questionStates[question.id]?.lapses ?? 0;

      final updatedState = _updateQuestionState(
        question: question,
        previousStability: previousStability,
        wasLapses: wasLapses,
        isCorrect: isCorrect,
        timeExpired: timeExpired,
        now: now,
      );

      questionStates[question.id] = updatedState;
      await questionStateRepository.saveQuestionState(updatedState);

      // Attemptを作成して保存
      final newAttempt = Attempt.fromAnswer(
        id: '${DateTime.now().millisecondsSinceEpoch}_${question.id}',
        questionId: question.id,
        mode: question.mode,
        domainId: question.domainId,
        subdomainId: question.subdomainId,
        answerType: question.answer.type,
        userAnswer: userAnswer,
        isCorrect: isCorrect,
        isSkip: isSkip,
        confidence: confidence,
        responseTimeMs: responseTimeMs,
        timeExpired: timeExpired,
        answeredAt: now,
        difficulty: question.difficulty,
      );
      await attemptRepository.saveAttempt(newAttempt);

      // 復習モードの場合、lastAttemptsを更新
      if (isReviewMode) {
        lastAttempts[question.id] = newAttempt;
      }

      await _updateUnitProgress(question);
      _refreshOverallScore();
      _refreshSkillProgressSnapshot();
      _snapshotSkillScores();

      if (advanceAfterSubmit) {
        _pickNextQuestion(previousId: question.id);
      }
      notifyListeners();
    } catch (error) {
      print('submitAnswer error: $error');
    }
  }


  void advanceToNextQuestion() {
    print('🔍 advanceToNextQuestion: currentId=$currentQuestionId, isReviewMode=$isReviewMode');
    _pickNextQuestion(previousId: currentQuestionId);
    print('🔍 after _pickNextQuestion: nextId=$currentQuestionId');
    notifyListeners();
  }

  void _pickNextQuestion({String? previousId}) {
    if (_questions.isEmpty) {
      currentQuestionId = null;
      return;
    }

    String? nextId;

    if (isReviewMode) {
      print('🔍 ReviewMode: candidates=${_questions.length}, states=${questionStates.length}, attempts=${lastAttempts.length}');

      // デバッグ: lapses > 0 の問題をカウント
      int lapsesCount = 0;
      int bothExistCount = 0;
      for (final q in _questions) {
        final state = questionStates[q.id];
        final attempt = lastAttempts[q.id];
        if (state != null && state.lapses > 0) {
          lapsesCount++;
          if (attempt != null) bothExistCount++;
        }
      }
      print('🔍 lapsesCount=$lapsesCount, bothExist=$bothExistCount, previousId=$previousId');

      // 復習モード：ReviewSchedulerを使用
      nextId = reviewScheduler.selectReviewQuestion(
        candidates: _questions,
        questionStates: questionStates,
        lastAttempts: lastAttempts,
        now: DateTime.now(),
      );
      print('🔍 ReviewScheduler returned: $nextId');
    } else {
      // 通常モード：Schedulerを使用
      nextId = scheduler.selectNextQuestion(
        candidates: _questions,
        questionStates: questionStates,
        skillStates: skillStates,
        now: DateTime.now(),
        skillScopeResolver: _skillScopeId,
      );
    }

    if (previousId != null && nextId == previousId && _questions.length > 1) {
      final remaining = _questions.where((q) => q.id != previousId).toList();

      if (isReviewMode) {
        final retryId = reviewScheduler.selectReviewQuestion(
          candidates: remaining,
          questionStates: questionStates,
          lastAttempts: lastAttempts,
          now: DateTime.now(),
        );
        // 再試行でも見つからない場合は、最初から選び直す
        currentQuestionId = retryId ?? reviewScheduler.selectReviewQuestion(
          candidates: _questions,
          questionStates: questionStates,
          lastAttempts: lastAttempts,
          now: DateTime.now(),
        ) ?? nextId;
      } else {
        currentQuestionId = scheduler.selectNextQuestion(
              candidates: remaining,
              questionStates: questionStates,
              skillStates: skillStates,
              now: DateTime.now(),
              skillScopeResolver: _skillScopeId,
            ) ??
            nextId;
      }
      return;
    }
    currentQuestionId = nextId ?? (_questions.isNotEmpty ? _questions.first.id : null);
  }

  List<Question> _filterQuestions(List<Question> source) {
    if (isRecommendedMode) {
      return source.where((q) => q.mode == mode).toList();
    }
    return source
        .where((question) => domainId == 'all' || question.domainId == domainId)
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
      final allAnswered =
          caseQuestions.isNotEmpty && caseQuestions.every((q) => answeredQuestionIds.contains(q.id));
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

    if (isFirstToday) {
      final updatedStreak = _calculateStreak(now);
      streakCount = updatedStreak.currentStreak;
      await streakStateRepository.saveStreakState(updatedStreak);
      lastUnitCompletedAt = updatedStreak.lastUnitCompletedAt;
      lastStudyDate = updatedStreak.lastStudyDate;

      // スコアスナップショットを保存（1日1回のみ）
      await scoreSnapshotService.saveCurrentScoreSnapshot();
    }

    _refreshSkillProgressSnapshot();
    _snapshotSkillScores();
    notifyListeners();
  }

  String _skillScopeId(Question question) {
    return mode == 'required' ? question.subdomainId : question.domainId;
  }

  Future<void> _loadSkillScopes() async {
    final asset = mode == 'required' ? 'assets/taxonomy_required.json' : 'assets/taxonomy_general.json';
    final domains = await taxonomyService.loadDomains(asset);
    skillLabels.clear();
    if (mode == 'required') {
      for (final domain in domains) {
        for (final subdomain in domain.subdomains) {
          skillLabels[subdomain.id] = subdomain.name;
        }
      }
    } else {
      for (final domain in domains) {
        skillLabels[domain.id] = domain.name;
      }
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
      ..addAll({for (final state in stored) state.questionId: state});
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
      overallScore = mode == 'required' ? 40 : 162.5;
      overallRank = 'B';
      return;
    }

    final scores = skillLabels.keys.map((skillId) {
      final theta = skillStates[skillId]?.theta ?? 0;
      return mode == 'required' ? scoreEngine.thetaToRequiredScore(theta) : scoreEngine.thetaToGeneralScore(theta);
    }).toList();

    overallScore = scores.reduce((a, b) => a + b) / scores.length;
    overallRank = mode == 'required'
        ? scoreEngine.requiredRankFromScore(overallScore)
        : scoreEngine.generalRankFromScore(overallScore);
  }

  void _refreshSkillProgressSnapshot() {
    if (skillLabels.isEmpty) {
      latestSkillProgress = [];
      lastOverallScore = overallScore;
      lastOverallRank = overallRank;
      return;
    }

    final previousScores = skillLabels.keys.map((skillId) {
      return lastSkillScores[skillId] ?? (mode == 'required' ? 40.0 : 162.5);
    }).toList();

    lastOverallScore = previousScores.reduce((a, b) => a + b) / previousScores.length;
    lastOverallRank = mode == 'required'
        ? scoreEngine.requiredRankFromScore(lastOverallScore)
        : scoreEngine.generalRankFromScore(lastOverallScore);

    latestSkillProgress = skillLabels.entries.map((entry) {
      final theta = skillStates[entry.key]?.theta ?? 0;
      final currentScore =
          mode == 'required' ? scoreEngine.thetaToRequiredScore(theta) : scoreEngine.thetaToGeneralScore(theta);
      return SkillProgress(
        skillId: entry.key,
        label: entry.value,
        currentScore: currentScore,
        previousScore: lastSkillScores[entry.key] ?? currentScore,
      );
    }).toList();
  }

  void _snapshotSkillScores() {
    lastSkillScores
      ..clear()
      ..addAll({
        for (final skillId in skillLabels.keys)
          skillId: mode == 'required'
              ? scoreEngine.thetaToRequiredScore(skillStates[skillId]?.theta ?? 0)
              : scoreEngine.thetaToGeneralScore(skillStates[skillId]?.theta ?? 0),
      });
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

}