import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/encouragement_messages.dart';
import '../services/user_score_service.dart';
import '../services/taxonomy_service.dart';

/// 今日の学習目標を表示するカード
class StudyGoalCard extends StatelessWidget {
  const StudyGoalCard({
    super.key,
    required this.onStartStudy,
  });

  final void Function(String mode, String domainId, String subdomainId) onStartStudy;

  @override
  Widget build(BuildContext context) {
    final userScoreService = UserScoreService();

    return FutureBuilder<_StudyGoalData>(
      future: _generateGoalData(userScoreService),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 180,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('データ取得エラー: ${snapshot.error}'),
            ),
          );
        }

        final data = snapshot.data!;
        return _StudyGoalCardContent(
          data: data,
          onStartStudy: onStartStudy,
        );
      },
    );
  }

  Future<_StudyGoalData> _generateGoalData(UserScoreService service) async {
    // 弱点領域を分析
    final weakDomain = await service.analyzeWeakestDomain();

    if (weakDomain != null) {
      // 弱点がある場合、その領域を推奨
      return _StudyGoalData(
        mode: weakDomain.isRequired ? 'required' : 'general',
        domainId: weakDomain.isRequired ? weakDomain.domainId : weakDomain.domainId,
        subdomainId: weakDomain.isRequired ? weakDomain.domainId : 'all',
        recommendedQuestions: 10,
        reason: '${weakDomain.domainName}が弱点です',
        displayName: weakDomain.isRequired ? '必修: ${weakDomain.domainName}' : weakDomain.domainName,
        encouragement: EncouragementMessages.randomStudyStart(),
      );
    }

    // 弱点がない場合、実際に存在する領域からランダムに選ぶ
    try {
      final taxonomyService = TaxonomyService();
      final isRequired = DateTime.now().millisecondsSinceEpoch % 2 == 0;
      
      if (isRequired) {
        // 必修の場合
        final domains = await taxonomyService.loadDomains('assets/taxonomy_required.json');
        if (domains.isNotEmpty && domains.first.subdomains.isNotEmpty) {
          final subdomain = domains.first.subdomains.first;
          return _StudyGoalData(
            mode: 'required',
            domainId: domains.first.id,
            subdomainId: subdomain.id,
            recommendedQuestions: 10,
            reason: 'バランスよく学習しましょう',
            displayName: '必修: ${subdomain.name}',
            encouragement: EncouragementMessages.randomStudyStart(),
          );
        }
      } else {
        // 一般の場合
        final domains = await taxonomyService.loadDomains('assets/taxonomy_general.json');
        if (domains.isNotEmpty) {
          final domain = domains.first;
          return _StudyGoalData(
            mode: 'general',
            domainId: domain.id,
            subdomainId: 'all',
            recommendedQuestions: 10,
            reason: 'バランスよく学習しましょう',
            displayName: domain.name,
            encouragement: EncouragementMessages.randomStudyStart(),
          );
        }
      }
    } catch (e) {
      print('StudyGoalCard._generateGoalData error: $e');
    }

    // フォールバック: データ取得失敗時
    return _StudyGoalData(
      mode: 'general',
      domainId: 'adult',
      subdomainId: 'all',
      recommendedQuestions: 10,
      reason: 'バランスよく学習しましょう',
      displayName: '一般・状況設定問題',
      encouragement: EncouragementMessages.randomStudyStart(),
    );
  }
}

class _StudyGoalCardContent extends StatelessWidget {
  const _StudyGoalCardContent({
    required this.data,
    required this.onStartStudy,
  });

  final _StudyGoalData data;
  final void Function(String mode, String domainId, String subdomainId) onStartStudy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: AppColors.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'おすすめの学習',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'AI提案',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        data.encouragement,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.scoreUp.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '推奨',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.scoreUp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '目安: ${data.recommendedQuestions}問',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (data.reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data.reason,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  onStartStudy(data.mode, data.domainId, data.subdomainId);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.play_arrow, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'このおすすめで学習する',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '※ 自分で領域を選びたい場合は下のタブから選択できます',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyGoalData {
  const _StudyGoalData({
    required this.mode,
    required this.domainId,
    required this.subdomainId,
    required this.recommendedQuestions,
    required this.reason,
    required this.displayName,
    required this.encouragement,
  });

  final String mode;
  final String domainId;
  final String subdomainId;
  final int recommendedQuestions;
  final String reason;
  final String displayName;
  final String encouragement;
}