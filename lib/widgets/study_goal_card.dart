import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 今日の学習目標を表示するカード
class StudyGoalCard extends StatelessWidget {
  const StudyGoalCard({
    super.key,
    required this.onStartStudy,
  });

  final void Function(String mode, String domainId, String subdomainId) onStartStudy;

  // TODO: 実際のデータから生成
  _StudyGoalData _getGoalData() {
    // 仮のデータ
    return _StudyGoalData(
      mode: 'required',
      domainId: 'basic',
      subdomainId: 'all',
      recommendedQuestions: 10,
      reason: '昨日は基礎看護が弱かったので',
      displayName: '必修問題',
      encouragement: '今日もお疲れさま! 一緒に頑張ろう 😊',
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _getGoalData();
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: AppColors.primaryContainer.withOpacity(0.3), // 背景色で目立たせる
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
                  child: Icon(
                    Icons.auto_awesome, // アイコン変更: 自動提案を示唆
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
                            'おすすめの学習', // タイトル変更
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
                              'AI提案', // バッジ追加
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
                      // 推奨バッジ
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
                      'このおすすめで学習する', // ボタンテキスト変更
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
            // 説明テキスト追加
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
