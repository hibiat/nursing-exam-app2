import 'package:flutter/material.dart';

import '../models/taxonomy.dart';
import '../repositories/question_state_repository.dart';
import '../services/taxonomy_service.dart';
import 'study_screen.dart';
import '../utils/user_friendly_error_messages.dart';

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
                Text(UserFriendlyErrorMessages.getErrorMessage(snapshot.error)),
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
            ? requiredItems.length + 1 + (data.reviewLoadFailed ? 1 : 0)  // +1 for all-domains card
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
            // For required mode, show "All Domains" card first
            if (isRequired) {
              final allDomainIndex = data.reviewLoadFailed ? 1 : 0;
              if (index == allDomainIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DomainCard(
                    title: '必修問題（全16領域）',
                    subtitle: '全領域からバランスよく出題',
                    reviewCount: 0,
                    icon: Icons.auto_awesome,
                    isHighlighted: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudyScreen(
                            mode: widget.mode,
                            domainId: 'required.core',
                            subdomainId: 'all',
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              
              // Show individual subdomain cards
              final requiredIndex = index - allDomainIndex - 1;
              final requiredItem = requiredItems[requiredIndex];
              return _DomainCard(
                title: requiredItem.label,
                subtitle: '特定領域を集中学習',
                reviewCount: 0,
                icon: Icons.local_hospital_outlined,
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
            }
            
            // For general mode
            if (!isRequired) {
              final domainIndex = data.reviewLoadFailed ? index - 1 : index;
              final domain = domains[domainIndex];
              final reviewCount = data.reviewCounts[domain.id] ?? 0;
              return _DomainCard(
                title: domain.name,
                subtitle: '領域ごとに5問ずつ',
                reviewCount: reviewCount,
                icon: Icons.favorite_border,
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
            
            return const SizedBox.shrink();
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
    required this.subtitle,
    required this.reviewCount,
    required this.icon,
    this.isHighlighted = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final int reviewCount;
  final IconData icon;
  final bool isHighlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleText = reviewCount > 0 ? '復習 $reviewCount 問' : null;
    final badge = reviewCount > 0
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '復習 $reviewCount',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isHighlighted ? 2 : 0.5,
      color: isHighlighted 
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (subtitleText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitleText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[
                badge,
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
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