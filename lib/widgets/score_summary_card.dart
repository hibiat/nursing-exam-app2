import 'package:flutter/material.dart';

import '../models/score_engine.dart';
import '../models/skill_state.dart';
import '../repositories/skill_state_repository.dart';
import '../services/taxonomy_service.dart';

class ScoreSummaryCard extends StatefulWidget {
  const ScoreSummaryCard({
    super.key,
    this.onStartOnboarding,
  });

  final VoidCallback? onStartOnboarding;

  @override
  State<ScoreSummaryCard> createState() => _ScoreSummaryCardState();
}

class _ScoreSummaryCardState extends State<ScoreSummaryCard> {
  final SkillStateRepository _skillStateRepository = SkillStateRepository();
  final ScoreEngine _scoreEngine = ScoreEngine();
  final TaxonomyService _taxonomyService = TaxonomyService();

  late Future<_SkillScopeConfig> _scopeFuture;
  int _reloadToken = 0;

  @override
  void initState() {
    super.initState();
    _scopeFuture = _loadSkillScopes();
  }

  Future<_SkillScopeConfig> _loadSkillScopes() async {
    final requiredDomains = await _taxonomyService.loadDomains('assets/taxonomy_required.json');
    final generalDomains = await _taxonomyService.loadDomains('assets/taxonomy_general.json');
    final requiredIds = <String>{};
    if (requiredDomains.isNotEmpty) {
      for (final subdomain in requiredDomains.first.subdomains) {
        requiredIds.add(subdomain.id);
      }
    }
    final generalIds = generalDomains.map((domain) => domain.id).toSet();
    return _SkillScopeConfig(
      requiredIds: requiredIds,
      generalIds: generalIds,
    );
  }

  void _retry() {
    setState(() {
      _reloadToken += 1;
      _scopeFuture = _loadSkillScopes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SkillScopeConfig>(
      future: _scopeFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ScoreSummaryCardLayout(
            requiredRank: '—',
            generalRank: '—',
            statusMessage: 'スコアの読み込みに失敗しました',
            onRetry: _retry,
            onStartOnboarding: widget.onStartOnboarding,
          );
        }
        final config = snapshot.data;
        if (config == null) {
          return _ScoreSummaryCardLayout(
            requiredRank: '診断中',
            generalRank: '診断中',
            statusMessage: 'スコアを読み込み中です',
            onStartOnboarding: widget.onStartOnboarding,
          );
        }
        return StreamBuilder<Map<String, SkillState>>(
          key: ValueKey(_reloadToken),
          stream: _skillStateRepository.watchSkillStates(),
          builder: (context, stateSnapshot) {
            if (stateSnapshot.hasError) {
              return _ScoreSummaryCardLayout(
                requiredRank: '—',
                generalRank: '—',
                statusMessage: 'スコアの取得に失敗しました',
                onRetry: _retry,
                onStartOnboarding: widget.onStartOnboarding,
              );
            }
            final skillStates = stateSnapshot.data ?? {};
            final requiredScore = _averageScore(config.requiredIds, skillStates);
            final generalScore = _averageScore(config.generalIds, skillStates);
            return _ScoreSummaryCardLayout(
              requiredRank: _rankFromScore(requiredScore),
              generalRank: _rankFromScore(generalScore),
              statusMessage: null,
              onStartOnboarding: widget.onStartOnboarding,
            );
          },
        );
      },
    );
  }

  double? _averageScore(Set<String> ids, Map<String, SkillState> skillStates) {
    if (ids.isEmpty) return null;
    final scores = ids
        .map((id) => skillStates[id])
        .whereType<SkillState>()
        .map((state) => _scoreEngine.scoreFromTheta(state.theta))
        .toList();
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  String _rankFromScore(double? score) {
    if (score == null) return '—';
    return _scoreEngine.rankFromScore(score);
  }
}

class _ScoreSummaryCardLayout extends StatelessWidget {
  const _ScoreSummaryCardLayout({
    required this.requiredRank,
    required this.generalRank,
    required this.statusMessage,
    this.onRetry,
    this.onStartOnboarding,
  });

  final String requiredRank;
  final String generalRank;
  final String? statusMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onStartOnboarding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headlineStyle = theme.textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    );
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('現在の実力', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ScoreColumn(
                    title: '必修',
                    rank: requiredRank,
                    rankStyle: headlineStyle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ScoreColumn(
                    title: '一般',
                    rank: generalRank,
                    rankStyle: headlineStyle,
                  ),
                ),
              ],
            ),
            if (statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                statusMessage!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onRetry,
                  child: const Text('再読み込み'),
                ),
              ),
            ],
            if (onStartOnboarding != null && requiredRank == '—' && generalRank == '—') ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onStartOnboarding,
                  child: const Text('初期スコアを設定する'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  const _ScoreColumn({
    required this.title,
    required this.rank,
    required this.rankStyle,
  });

  final String title;
  final String rank;
  final TextStyle? rankStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(rank, style: rankStyle),
        const SizedBox(height: 4),
        Text('総合ランク', style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _SkillScopeConfig {
  const _SkillScopeConfig({
    required this.requiredIds,
    required this.generalIds,
  });

  final Set<String> requiredIds;
  final Set<String> generalIds;
}
