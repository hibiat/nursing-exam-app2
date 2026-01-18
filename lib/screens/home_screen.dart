import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../repositories/user_profile_repository.dart';
import '../widgets/score_summary_card.dart';
import '../widgets/study_goal_card.dart';
import '../widgets/passing_prediction_card.dart';
import 'onboarding_exam_screen.dart';
import 'select_screen.dart';
import 'settings_screen.dart';
import 'study_screen.dart'; // 新規追加
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<void> _authFuture;
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
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('認証に失敗しました: ${snapshot.error}'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _retryAuth,
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),
          );
        }
        _maybeShowOnboardingDialog();
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('看護師国家試験アプリ'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: '設定',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                // スクロール可能なヘッダーセクション
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // 合格予測カード
                      SliverToBoxAdapter(
                        child: PassingPredictionCard(),
                      ),
                      
                      // 今日の学習目標カード
                      SliverToBoxAdapter(
                        child: StudyGoalCard(
                          onStartStudy: (mode, domainId, subdomainId) {
                            // 学習画面へ遷移
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StudyScreen(
                                  mode: mode,
                                  domainId: domainId,
                                  subdomainId: subdomainId,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // スコアサマリー
                      SliverToBoxAdapter(
                        child: ScoreSummaryCard(
                          onStartOnboarding:
                              _profile?.onboardingCompleted == true ? null : _startOnboardingExam,
                        ),
                      ),
                      
                      // タブバー(セクション見出しを追加)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.list_alt,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '領域を選んで学習する',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverTabBarDelegate(
                          const TabBar(
                            tabs: [
                              Tab(text: '必修'),
                              Tab(text: '一般・状況設定'),
                            ],
                          ),
                        ),
                      ),
                      
                      // タブビュー内容をSliverに
                      SliverFillRemaining(
                        child: TabBarView(
                          children: const [
                            SelectScreen(mode: 'required'),
                            SelectScreen(mode: 'general'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

// TabBarをSliverで使うためのDelegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}