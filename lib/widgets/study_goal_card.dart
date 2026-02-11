import 'package:flutter/material.dart';

import '../constants/encouragement_messages.dart';
import '../services/user_score_service.dart';
import '../utils/user_friendly_error_messages.dart';

/// 女子看護学生向けのトーンで、AIおすすめ学習をわかりやすく提示するカード
class StudyGoalCard extends StatelessWidget {
  const StudyGoalCard({
    super.key,
    required this.onStartStudy,
  });

  final void Function(String mode) onStartStudy;

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
              height: 160,
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
              child: Text(UserFriendlyErrorMessages.getErrorMessage(snapshot.error)),
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
    final weakDomain = await service.analyzeWeakestDomain();

    if (weakDomain != null) {
      return _StudyGoalData(
        mode: weakDomain.isRequired ? 'required' : 'general',
        subTitle: '${weakDomain.domainName}を中心に解いてみましょう',
        encouragement: EncouragementMessages.randomStudyStart(),
      );
    }

    final isRequired = DateTime.now().millisecondsSinceEpoch % 2 == 0;
    return _StudyGoalData(
      mode: isRequired ? 'required' : 'general',
      subTitle: '今の実力に合わせて、最適な順番で出題します',
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
  final void Function(String mode) onStartStudy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEEF6), Color(0xFFFFF8EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD5E8), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AB76E93),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF17CB0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AIおすすめ学習',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFBA4D82),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.encouragement,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8A6A7A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.82),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD9E9)),
              ),
              child: Text(
                data.subTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5D4A55),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => onStartStudy(data.mode),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFE56AA3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'このおすすめで学習を始める',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
    required this.subTitle,
    required this.encouragement,
  });

  final String mode;
  final String subTitle;
  final String encouragement;
}
