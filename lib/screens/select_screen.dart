import 'package:flutter/material.dart';

import '../models/taxonomy.dart';
import '../repositories/question_state_repository.dart';
import '../services/taxonomy_service.dart';
import 'study_screen.dart';

class SelectScreen extends StatefulWidget {
  const SelectScreen({super.key, required this.mode});

  final String mode;

  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  final TaxonomyService taxonomyService = TaxonomyService();
  final QuestionStateRepository questionStateRepository = QuestionStateRepository();

  Future<_SelectScreenData> _loadData() async {
    final asset = widget.mode == 'required'
        ? 'assets/taxonomy_required.json'
        : 'assets/taxonomy_general.json';
    final domains = await taxonomyService.loadDomains(asset);
    Map<String, int> reviewCounts = {};
    bool reviewLoadFailed = false;
    try {
      reviewCounts = await questionStateRepository.fetchDueCountsByDomain(
        mode: widget.mode,
      );
    } catch (_) {
      reviewLoadFailed = true;
    }
    return _SelectScreenData(
      domains: domains,
      reviewCounts: reviewCounts,
      reviewLoadFailed: reviewLoadFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRequired = widget.mode == 'required';
    return FutureBuilder<_SelectScreenData>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('分類データの読み込みに失敗しました'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => setState(() {}),
                  child: const Text('再試行'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final domains = data.domains;
        if (domains.isEmpty) {
          return const Center(child: Text('分類データがありません'));
        }
        final requiredItems = isRequired
            ? domains
                .expand(
                  (domain) => domain.subdomains.map(
                    (subdomain) => _RequiredSubdomainItem(
                      domainId: domain.id,
                      subdomainId: subdomain.id,
                      label: subdomain.name,
                    ),
                  ),
                )
                .toList()
            : <_RequiredSubdomainItem>[];
        final listCount = isRequired
            ? requiredItems.length + (data.reviewLoadFailed ? 1 : 0)
            : domains.length + (data.reviewLoadFailed ? 1 : 0);
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: listCount,
          itemBuilder: (context, index) {
            if (data.reviewLoadFailed && index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  '復習数の取得に失敗しました。分類は表示されています。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }
            if (!isRequired) {
              final domainIndex = data.reviewLoadFailed ? index - 1 : index;
              final domain = domains[domainIndex];
              final reviewCount = data.reviewCounts[domain.id] ?? 0;
              return _DomainCard(
                title: domain.name,
                reviewCount: reviewCount,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudyScreen(
                        mode: widget.mode,
                        domainId: domain.id,
                        subdomainId: 'all',
                      ),
                    ),
                  );
                },
              );
            }
            final requiredIndex = data.reviewLoadFailed ? index - 1 : index;
            final requiredItem = requiredItems[requiredIndex];
            return _DomainCard(
              title: requiredItem.label,
              reviewCount: 0,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudyScreen(
                      mode: widget.mode,
                      domainId: requiredItem.domainId,
                      subdomainId: requiredItem.subdomainId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SelectScreenData {
  const _SelectScreenData({
    required this.domains,
    required this.reviewCounts,
    required this.reviewLoadFailed,
  });

  final List<TaxonomyDomain> domains;
  final Map<String, int> reviewCounts;
  final bool reviewLoadFailed;
}

class _DomainCard extends StatelessWidget {
  const _DomainCard({
    required this.title,
    required this.reviewCount,
    this.onTap,
  });

  final String title;
  final int reviewCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = reviewCount > 0 ? Text('復習 $reviewCount 問') : null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(title),
        subtitle: subtitle,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _RequiredSubdomainItem {
  const _RequiredSubdomainItem({
    required this.domainId,
    required this.subdomainId,
    required this.label,
  });

  final String domainId;
  final String subdomainId;
  final String label;
}
