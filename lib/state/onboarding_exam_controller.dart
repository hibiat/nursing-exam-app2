import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/question.dart';
import '../models/score_engine.dart';
import '../models/skill_state.dart';
import '../models/user_profile.dart';
import '../repositories/skill_state_repository.dart';
import '../repositories/user_profile_repository.dart';
import '../services/question_set_service.dart';
import '../services/taxonomy_service.dart';

class OnboardingExamController extends ChangeNotifier {
  OnboardingExamController({
    QuestionSetService? questionSetService,
    SkillStateRepository? skillStateRepository,
    UserProfileRepository? userProfileRepository,
  })  : questionSetService = questionSetService ?? QuestionSetService(),
        skillStateRepository = skillStateRepository ?? SkillStateRepository(),
        userProfileRepository = userProfileRepository ?? UserProfileRepository();

  final QuestionSetService questionSetService;
  final SkillStateRepository skillStateRepository;
  final UserProfileRepository userProfileRepository;
  final TaxonomyService taxonomyService = TaxonomyService();
  final ScoreEngine scoreEngine = ScoreEngine();

  List<Question> questions = [];
  int currentIndex = 0;
  bool isLoading = true;
  String? loadError;
  bool isCompleted = false;

  final Map<String, SkillState> skillStates = {};
  final Set<String> skillScopeIds = {};
  UserProfile? profile;

  Question? get currentQuestion {
    if (currentIndex < 0 || currentIndex >= questions.length) return null;
    return questions[currentIndex];
  }

  int get totalQuestions => questions.length;

  double get summaryScore {
    if (skillStates.isEmpty) return 40; // デフォルト: 必修の合格ライン
    
    // 必修と一般を分けて計算して平均
    final requiredStates = skillStates.entries
        .where((e) => questions.any((q) => q.mode == 'required' && q.subdomainId == e.key));
    final generalStates = skillStates.entries
        .where((e) => questions.any((q) => q.mode == 'general' && q.domainId == e.key));
    
    final requiredScores = requiredStates
        .map((e) => scoreEngine.thetaToRequiredScore(e.value.theta))
        .toList();
    final generalScores = generalStates
        .map((e) => scoreEngine.thetaToGeneralScore(e.value.theta))
        .toList();
    
    // 必修は50点満点、一般は250点満点なので正規化して平均
    final requiredAvg = requiredScores.isEmpty 
        ? 40.0 
        : requiredScores.reduce((a, b) => a + b) / requiredScores.length;
    final generalAvg = generalScores.isEmpty 
        ? 162.5 
        : generalScores.reduce((a, b) => a + b) / generalScores.length;
    
    // 両方を50点満点に正規化して平均
    final requiredNormalized = requiredAvg; // 既に50点満点
    final generalNormalized = generalAvg / 5; // 250点満点 → 50点満点
    
    return (requiredNormalized + generalNormalized) / 2;
  }

  String get summaryRank {
    // summaryScoreは50点満点に正規化されているので、必修の基準で判定
    return scoreEngine.requiredRankFromScore(summaryScore);
  }

  Future<void> start() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      profile = await userProfileRepository.fetchProfile();
      final requiredQuestions = await questionSetService.loadActiveQuestions(mode: 'required');
      final generalQuestions = await questionSetService.loadActiveQuestions(mode: 'general');
      if (requiredQuestions.isEmpty && generalQuestions.isEmpty) {
        loadError = '有効な問題セットがありません';
        isLoading = false;
        notifyListeners();
        return;
      }
      await _loadSkillScopes();
      final selected = <Question>[
        ..._pickSample(requiredQuestions, 5),
        ..._pickSample(generalQuestions, 5),
      ];
      selected.shuffle(Random());
      questions = selected;
      currentIndex = 0;
      isCompleted = false;
    } catch (error) {
      loadError = error.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> submitAnswer({
    required String? chosen,
    required bool isSkip,
  }) async {
    if (isCompleted) return;
    final question = currentQuestion;
    if (question == null) return;
    final isCorrect = chosen != null && chosen == question.answer && !isSkip;
    final scopeId = question.mode == 'required' ? question.subdomainId : question.domainId;
    final current = skillStates[scopeId] ??
        SkillState(
          skillId: scopeId,
          theta: 0,
          nEff: 0,
          lastUpdatedAt: DateTime.now(),
        );
    final result = scoreEngine.updateTheta(
      theta: current.theta,
      isCorrect: isCorrect,
      isSkip: isSkip,
      timeExpired: false,
      wasIncorrectBefore: false,
      wasMostlyCorrect: false,
      confidence: null,
      difficulty: question.difficulty,
    );
    skillStates[scopeId] = SkillState(
      skillId: scopeId,
      theta: result.theta,
      nEff: current.nEff + 1,
      lastUpdatedAt: DateTime.now(),
    );
    currentIndex += 1;
    if (currentIndex >= questions.length) {
      await _completeExam();
    }
    notifyListeners();
  }

  Future<void> _loadSkillScopes() async {
    final requiredDomains = await taxonomyService.loadDomains('assets/taxonomy_required.json');
    final generalDomains = await taxonomyService.loadDomains('assets/taxonomy_general.json');
    skillScopeIds
      ..clear()
      ..addAll(
        requiredDomains.isEmpty
            ? const Iterable<String>.empty()
            : requiredDomains.first.subdomains.map((subdomain) => subdomain.id),
      )
      ..addAll(generalDomains.map((domain) => domain.id));
  }

  List<Question> _pickSample(List<Question> source, int count) {
    if (source.isEmpty) return [];
    final items = [...source]..shuffle(Random());
    if (items.length <= count) return items;
    return items.take(count).toList();
  }

  Future<void> _completeExam() async {
    isCompleted = true;
    final now = DateTime.now();
    for (final skillId in skillScopeIds) {
      final state = skillStates[skillId] ??
          SkillState(
            skillId: skillId,
            theta: 0,
            nEff: 0,
            lastUpdatedAt: now,
          );
      await skillStateRepository.saveSkillState(
        state.copyWith(lastUpdatedAt: now),
      );
    }
    await userProfileRepository.saveProfile(
      UserProfile(
        onboardingCompleted: true,
        onboardingPromptedAt: profile?.onboardingPromptedAt,
        onboardingCompletedAt: now,
      ),
    );
  }
}