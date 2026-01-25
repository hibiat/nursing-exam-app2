import 'package:flutter/material.dart';
import '../models/score_engine.dart';
import '../repositories/skill_state_repository.dart';
import '../services/taxonomy_service.dart';

class ScoreSummaryCard extends StatelessWidget {
  const ScoreSummaryCard({
    super.key,
    this.onStartOnboarding,
  });

  final VoidCallback? onStartOnboarding;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ScoreSummaryData>(
      future: _loadScoreData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '必修',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'ランク ${data.requiredRank}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '一般・状況',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'ランク ${data.generalRank}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (onStartOnboarding != null) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onStartOnboarding,
                    child: const Text('初期スコア測定を開始'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_ScoreSummaryData> _loadScoreData() async {
    final scoreEngine = ScoreEngine();
    final skillStateRepo = SkillStateRepository();
    final taxonomyService = TaxonomyService();

    try {
      // 必修のスコア計算
      final requiredDomains = await taxonomyService.loadDomains('assets/taxonomy_required.json');
      final requiredSkillIds = requiredDomains.isNotEmpty
          ? requiredDomains.first.subdomains.map((s) => s.id).toList()
          : <String>[];
      final requiredStates = await skillStateRepo.fetchSkillStates(requiredSkillIds);
      final requiredScores = requiredSkillIds
          .map((id) => scoreEngine.thetaToRequiredScore(requiredStates[id]?.theta ?? 0))
          .toList();
      final requiredScore = requiredScores.isEmpty
          ? 40.0
          : requiredScores.reduce((a, b) => a + b) / requiredScores.length;
      final requiredRank = scoreEngine.requiredRankFromScore(requiredScore);

      // 一般のスコア計算
      final generalDomains = await taxonomyService.loadDomains('assets/taxonomy_general.json');
      final generalSkillIds = generalDomains.map((d) => d.id).toList();
      final generalStates = await skillStateRepo.fetchSkillStates(generalSkillIds);
      final generalScores = generalSkillIds
          .map((id) => scoreEngine.thetaToGeneralScore(generalStates[id]?.theta ?? 0))
          .toList();
      final generalScore = generalScores.isEmpty
          ? 162.5
          : generalScores.reduce((a, b) => a + b) / generalScores.length;
      final generalRank = scoreEngine.generalRankFromScore(generalScore);

      return _ScoreSummaryData(
        requiredRank: requiredRank,
        generalRank: generalRank,
      );
    } catch (e) {
      return _ScoreSummaryData(
        requiredRank: 'B',
        generalRank: 'B',
      );
    }
  }
}

class _ScoreSummaryData {
  const _ScoreSummaryData({
    required this.requiredRank,
    required this.generalRank,
  });

  final String requiredRank;
  final String generalRank;
}