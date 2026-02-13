import 'package:flutter/material.dart';

import '../models/score_engine.dart';
import '../models/skill_state.dart';
import '../services/taxonomy_service.dart';
import '../repositories/skill_state_repository.dart';
import '../utils/user_friendly_error_messages.dart';

class DomainScoresScreen extends StatelessWidget {
  const DomainScoresScreen({super.key, required this.mode});

  final String mode; // required | general

  @override
  Widget build(BuildContext context) {
    final title = mode == 'required' ? '必修の分野別スコア' : '一般・状況設定の分野別スコア';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<_DomainScoreItem>>(
        future: _loadScores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(UserFriendlyErrorMessages.getErrorMessage(snapshot.error)),
            );
          }

          final items = snapshot.data ?? const <_DomainScoreItem>[];
          if (items.isEmpty) {
            return const Center(child: Text('分野スコアがまだありません'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final color = _rankColor(item.rank, Theme.of(context));
              return Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text('スコア ${item.scoreLabel}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ランク ${item.rank}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<_DomainScoreItem>> _loadScores() async {
    final taxonomyService = TaxonomyService();
    final scoreEngine = ScoreEngine();
    final skillRepo = SkillStateRepository();

    if (mode == 'required') {
      final domains = await taxonomyService.loadDomains('assets/taxonomy_required.json');
      if (domains.isEmpty) return const [];

      final subdomains = domains.first.subdomains;
      final ids = subdomains.map((e) => e.id);
      final states = await skillRepo.fetchSkillStates(ids);

      return subdomains.map((subdomain) {
        final state = states[subdomain.id] ??
            SkillState(
              skillId: subdomain.id,
              theta: -8,
              nEff: 0,
              lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(0),
            );
        final score = scoreEngine.thetaToRequiredScore(state.theta);
        final rank = scoreEngine.requiredRankFromScore(score);
        return _DomainScoreItem(
          name: subdomain.name,
          scoreLabel: '${score.toStringAsFixed(1)} / 50',
          rank: rank,
        );
      }).toList();
    }

    final domains = await taxonomyService.loadDomains('assets/taxonomy_general.json');
    final ids = domains.map((e) => e.id);
    final states = await skillRepo.fetchSkillStates(ids);

    return domains.map((domain) {
      final state = states[domain.id] ??
          SkillState(
            skillId: domain.id,
            theta: -8,
            nEff: 0,
            lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(0),
          );
      final score = scoreEngine.thetaToGeneralScore(state.theta);
      final rank = scoreEngine.generalRankFromScore(score);
      return _DomainScoreItem(
        name: domain.name,
        scoreLabel: '${score.toStringAsFixed(1)} / 250',
        rank: rank,
      );
    }).toList();
  }

  Color _rankColor(String rank, ThemeData theme) {
    switch (rank) {
      case 'S':
      case 'A':
        return Colors.green;
      case 'B':
        return theme.colorScheme.primary;
      case 'C':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }
}

class _DomainScoreItem {
  const _DomainScoreItem({
    required this.name,
    required this.scoreLabel,
    required this.rank,
  });

  final String name;
  final String scoreLabel;
  final String rank;
}
