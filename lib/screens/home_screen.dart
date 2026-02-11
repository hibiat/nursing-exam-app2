import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../repositories/user_profile_repository.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../utils/user_friendly_error_messages.dart';
import '../widgets/passing_prediction_card.dart';
import '../widgets/score_summary_card.dart';
import '../widgets/study_goal_card.dart';
import 'onboarding_exam_screen.dart';
import 'select_screen.dart';
import 'settings_screen.dart';
import 'study_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.themeService});

  final ThemeService themeService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<void> _authFuture;
  final UserProfileRepository userProfileRepository = UserProfileRepository();
  UserProfile? _profile;
  bool _onboardingDialogShown = false;

  @override
  void initState() {
    super.initState();
    _authFuture = _initAuth();
  }

  Future<void> _initAuth() async {
    final user = await AuthService.ensureSignedIn();
    print('Signed in uid=${user.uid}');
    _profile = await userProfileRepository.fetchProfile();
  }

  void _retryAuth() {
    setState(() {
      _authFuture = _initAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _authFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(UserFriendlyErrorMessages.getErrorMessage(snapshot.error)),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _retryAuth, child: const Text('再試行')),
                ],
              ),
            ),
          );
        }
        _maybeShowOnboardingDialog();

        return Scaffold(
          appBar: AppBar(
            title: const Text('看護師国家試験アプリ'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: '設定',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(themeService: widget.themeService),
                    ),
                  );
                },
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _MainActionCard(
                  needsOnboarding: _profile?.onboardingCompleted != true,
                  onStartOnboarding: _startOnboardingExam,
                  onStartRecommendedStudy: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StudyScreen.recommended(mode: 'required'),
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: PassingPredictionCard()),
              SliverToBoxAdapter(
                child: StudyGoalCard(
                  onStartStudy: (mode) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudyScreen.recommended(mode: mode),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: ScoreSummaryCard(
                  onStartOnboarding:
                      _profile?.onboardingCompleted == true ? null : _startOnboardingExam,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    '領域を選んで学習',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DomainCategoryCard(
                          title: '必修問題',
                          icon: Icons.local_hospital,
                          onTap: () => _openSelectScreen('required'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DomainCategoryCard(
                          title: '一般・状況設定',
                          icon: Icons.menu_book,
                          onTap: () => _openSelectScreen('general'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSelectScreen(String mode) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SelectScreen(mode: mode)),
    );
  }

  void _maybeShowOnboardingDialog() {
    if (_onboardingDialogShown) return;
    final profile = _profile;
    final needsPrompt =
        profile == null || (!profile.onboardingCompleted && profile.onboardingPromptedAt == null);
    if (!needsPrompt) return;
    _onboardingDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final shouldStart = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            scrollable: true,
            title: const Text('ショート模試を始めますか?'),
            content: const Text(
              '評価ではなく、今の実力の目安を知るためのミニテストです。\n'
              '10問ほど解いて、初期スコアを推定します。\n'
              '後からいつでも実施できます。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('後で'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('今すぐ実施'),
              ),
            ],
          );
        },
      );
      await _markOnboardingPrompted();
      if (shouldStart == true) {
        _startOnboardingExam();
      }
    });
  }

  Future<void> _markOnboardingPrompted() async {
    final now = DateTime.now();
    await userProfileRepository.saveProfile(
      UserProfile(
        onboardingCompleted: _profile?.onboardingCompleted ?? false,
        onboardingPromptedAt: now,
        onboardingCompletedAt: _profile?.onboardingCompletedAt,
      ),
    );
    setState(() {
      _profile = UserProfile(
        onboardingCompleted: _profile?.onboardingCompleted ?? false,
        onboardingPromptedAt: now,
        onboardingCompletedAt: _profile?.onboardingCompletedAt,
      );
    });
  }

  Future<void> _startOnboardingExam() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingExamScreen()),
    );
    final updatedProfile = await userProfileRepository.fetchProfile();
    setState(() {
      _profile = updatedProfile;
    });
  }
}

class _MainActionCard extends StatelessWidget {
  const _MainActionCard({
    required this.needsOnboarding,
    required this.onStartOnboarding,
    required this.onStartRecommendedStudy,
  });

  final bool needsOnboarding;
  final VoidCallback onStartOnboarding;
  final VoidCallback onStartRecommendedStudy;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              needsOnboarding ? '最初に実力を測定しましょう' : '今日のおすすめ学習',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              needsOnboarding
                  ? '10問のショート模試で、現在地を把握できます。'
                  : '弱点領域から優先して出題します。',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: needsOnboarding ? onStartOnboarding : onStartRecommendedStudy,
              icon: const Icon(Icons.play_arrow),
              label: Text(needsOnboarding ? '初期スコア測定を開始' : '学習を始める'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DomainCategoryCard extends StatelessWidget {
  const _DomainCategoryCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
