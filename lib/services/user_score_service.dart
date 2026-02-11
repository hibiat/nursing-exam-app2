import '../models/score_engine.dart';
import '../models/skill_state.dart';
import '../repositories/skill_state_repository.dart';
import '../services/taxonomy_service.dart';

/// ユーザーの総合スコアを計算するサービス
class UserScoreService {
  UserScoreService({
    SkillStateRepository? skillStateRepository,
    TaxonomyService? taxonomyService,
    ScoreEngine? scoreEngine,
  })  : _skillStateRepository = skillStateRepository ?? SkillStateRepository(),
        _taxonomyService = taxonomyService ?? TaxonomyService(),
        _scoreEngine = scoreEngine ?? ScoreEngine();

  final SkillStateRepository _skillStateRepository;
  final TaxonomyService _taxonomyService;
  final ScoreEngine _scoreEngine;

  /// 必修問題の総合スコアを計算(50点満点)
  Future<double> calculateRequiredScore() async {
    try {
      final domains = await _taxonomyService.loadDomains('assets/taxonomy_required.json');
      if (domains.isEmpty) {
        return 40.0;
      }

      final skillIds = domains.first.subdomains.map((s) => s.id).toList();
      final skillStates = await _skillStateRepository.fetchSkillStates(skillIds);

      final scores = skillIds.map((id) {
        final theta = skillStates[id]?.theta ?? 0.0;
        return _scoreEngine.thetaToRequiredScore(theta);
      }).toList();

      if (scores.isEmpty) {
        return 40.0;
      }

      return scores.reduce((a, b) => a + b) / scores.length;
    } catch (e) {
      print('UserScoreService.calculateRequiredScore error: $e');
      return 40.0;
    }
  }

  /// 一般・状況設定問題の総合スコアを計算(250点満点)
  Future<double> calculateGeneralScore() async {
    try {
      final domains = await _taxonomyService.loadDomains('assets/taxonomy_general.json');
      if (domains.isEmpty) {
        return 162.5;
      }

      final skillIds = domains.map((d) => d.id).toList();
      final skillStates = await _skillStateRepository.fetchSkillStates(skillIds);

      final scores = skillIds.map((id) {
        final theta = skillStates[id]?.theta ?? 0.0;
        return _scoreEngine.thetaToGeneralScore(theta);
      }).toList();

      if (scores.isEmpty) {
        return 162.5;
      }

      return scores.reduce((a, b) => a + b) / scores.length;
    } catch (e) {
      print('UserScoreService.calculateGeneralScore error: $e');
      return 162.5;
    }
  }

  /// 合格予測データを取得（％表示なし）
  Future<PassingPredictionData> getPredictionData() async {
    final requiredScore = await calculateRequiredScore();
    final generalScore = await calculateGeneralScore();

    final requiredRank = _scoreEngine.requiredRankFromScore(requiredScore);
    final generalRank = _scoreEngine.generalRankFromScore(generalScore);

    final isPassing = requiredScore >= 40 && generalScore >= 150;

    final requiredGap = isPassing ? 0.0 : (40 - requiredScore).clamp(0.0, 40.0);
    final generalGap = isPassing ? 0.0 : (150 - generalScore).clamp(0.0, 150.0);

    return PassingPredictionData(
      requiredScore: requiredScore,
      generalScore: generalScore,
      requiredRank: requiredRank,
      generalRank: generalRank,
      isPassing: isPassing,
      requiredGap: requiredGap,
      generalGap: generalGap,
    );
  }

  /// 弱点領域を分析(スコアが最も低い領域を返す)
  Future<WeakDomainAnalysis?> analyzeWeakestDomain() async {
    try {
      final requiredDomains = await _taxonomyService.loadDomains('assets/taxonomy_required.json');
      final generalDomains = await _taxonomyService.loadDomains('assets/taxonomy_general.json');

      final requiredSkillIds = requiredDomains.isNotEmpty
          ? requiredDomains.first.subdomains.map((s) => s.id).toList()
          : <String>[];
      final generalSkillIds = generalDomains.map((d) => d.id).toList();

      final allSkillIds = [...requiredSkillIds, ...generalSkillIds];
      final skillStates = await _skillStateRepository.fetchSkillStates(allSkillIds);

      if (skillStates.isEmpty) {
        return null;
      }

      String? weakestId;
      double lowestScore = double.infinity;
      bool isRequired = false;

      for (final id in requiredSkillIds) {
        final theta = skillStates[id]?.theta ?? 0.0;
        final score = _scoreEngine.thetaToRequiredScore(theta);
        if (score < lowestScore) {
          lowestScore = score;
          weakestId = id;
          isRequired = true;
        }
      }

      for (final id in generalSkillIds) {
        final theta = skillStates[id]?.theta ?? 0.0;
        final score = _scoreEngine.thetaToGeneralScore(theta);
        final normalizedScore = score / 5;
        if (normalizedScore < lowestScore) {
          lowestScore = normalizedScore;
          weakestId = id;
          isRequired = false;
        }
      }

      if (weakestId == null) {
        return null;
      }

      String domainName = '不明';
      if (isRequired) {
        final subdomain = requiredDomains.first.subdomains.firstWhere(
          (s) => s.id == weakestId,
          orElse: () => requiredDomains.first.subdomains.first,
        );
        domainName = subdomain.name;
      } else {
        final domain = generalDomains.firstWhere(
          (d) => d.id == weakestId,
          orElse: () => generalDomains.first,
        );
        domainName = domain.name;
      }

      return WeakDomainAnalysis(
        domainId: weakestId,
        domainName: domainName,
        score: lowestScore,
        isRequired: isRequired,
      );
    } catch (e) {
      print('UserScoreService.analyzeWeakestDomain error: $e');
      return null;
    }
  }
}

class PassingPredictionData {
  const PassingPredictionData({
    required this.requiredScore,
    required this.generalScore,
    required this.requiredRank,
    required this.generalRank,
    required this.isPassing,
    required this.requiredGap,
    required this.generalGap,
  });

  final double requiredScore;
  final double generalScore;
  final String requiredRank;
  final String generalRank;
  final bool isPassing;
  final double requiredGap;
  final double generalGap;
}

class WeakDomainAnalysis {
  const WeakDomainAnalysis({
    required this.domainId,
    required this.domainName,
    required this.score,
    required this.isRequired,
  });

  final String domainId;
  final String domainName;
  final double score;
  final bool isRequired;
}
