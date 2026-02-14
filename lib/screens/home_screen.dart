import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../repositories/study_stats_repository.dart';
import '../repositories/user_profile_repository.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../utils/user_friendly_error_messages.dart';
import '../widgets/passing_prediction_card.dart';
import '../widgets/source_attribution_section.dart';
import '../widgets/study_goal_card.dart';
import 'learning_record_screen.dart';
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
  final StudyStatsRepository _statsRepository = StudyStatsRepository();
  UserProfile? _profile;
  bool _onboardingDialogShown = false;
  int _selectedTab = 0;
  Key _homeTabKey = UniqueKey(); // データ更新時にホームタブを再構築するためのキー

  @override
  void initState() {
    super.initState();
    _authFuture = _initAuth();
  }

  Future<void> _initAuth() async {
    final user = AuthService.currentUser;
    if (user != null) {
      print('Signed in uid=${user.uid}');
    }
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
          appBar: AppBar(title: const Text('看護師国家試験アプリ')),
          body: IndexedStack(
            index: _selectedTab,
            children: [
              _buildHomeTab(),
              _buildStudyTab(),
              _buildRecordTab(),
              _buildOtherTab(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) => setState(() => _selectedTab = index),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'ホーム'),
              NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: '学習'),
              NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: '記録'),
              NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'その他'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      key: _homeTabKey,
      slivers: [
        SliverToBoxAdapter(
          child: _MainActionCard(
            needsOnboarding: _profile?.onboardingCompleted != true,
            onStartOnboarding: _startOnboardingExam,
          ),
        ),
        SliverToBoxAdapter(child: PassingPredictionCard(key: ValueKey(_homeTabKey))),
        SliverToBoxAdapter(
          child: StudyGoalCard(
            onStartStudy: (mode) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => StudyScreen.recommended(mode: mode)),
              );
            },
          ),
        ),
        // 分野を選んで学習
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '分野を選んで学習',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openSelectScreen('required'),
                        icon: const Icon(Icons.local_hospital, size: 20),
                        label: const Text('必修'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openSelectScreen('general'),
                        icon: const Icon(Icons.menu_book, size: 20),
                        label: const Text('一般・状況'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 復習モードボタン
                Text(
                  '間違えた問題に絞って学習',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _startReviewMode(context),
                    icon: const Icon(Icons.replay, size: 20),
                    label: const Text('間違えた問題を復習する'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AIおすすめ学習セクション
        Text(
          'AIおすすめ学習',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _startOnboardingExam,
          icon: const Icon(Icons.play_circle_outline),
          label: const Text('ショート模試を開始'),
        ),
        const SizedBox(height: 8),
        StudyGoalCard(
          onStartStudy: (mode) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StudyScreen.recommended(mode: mode)),
            );
          },
        ),
        const SizedBox(height: 24),

        // 分野を選んで学習セクション
        Text(
          '分野を選んで学習',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _DomainCategoryCard(
          title: '必修問題',
          icon: Icons.local_hospital,
          onTap: () => _openSelectScreen('required'),
        ),
        const SizedBox(height: 12),
        _DomainCategoryCard(
          title: '一般・状況設定',
          icon: Icons.menu_book,
          onTap: () => _openSelectScreen('general'),
        ),
        const SizedBox(height: 16),
        // 復習モードボタン
        Text(
          '間違えた問題に絞って学習',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _startReviewMode(context),
            icon: const Icon(Icons.replay, size: 20),
            label: const Text('間違えた問題を復習する'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordTab() {
    return const LearningRecordScreen(isEmbedded: true);
  }

  Widget _buildOtherTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('設定'),
            onTap: () async {
              final wasReset = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => SettingsScreen(themeService: widget.themeService)),
              );
              final updatedProfile = await userProfileRepository.fetchProfile();
              if (!mounted) return;
              setState(() {
                _profile = updatedProfile;
                _onboardingDialogShown = false;
                // 学習履歴がリセットされた場合、ホームタブを再構築
                if (wasReset == true) {
                  _homeTabKey = UniqueKey();
                }
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              'ログアウト',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ログアウト'),
                  content: const Text('本当にログアウトしますか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('キャンセル'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('ログアウト'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await AuthService.signOut();
                // 認証状態が変わるとStreamBuilderが自動的にLoginScreenに戻る
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SourceAttributionSection(),
          ),
        ),
      ],
    );
  }

  void _openSelectScreen(String mode) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SelectScreen(mode: mode)),
    );
  }

  /// 復習モードを開始
  Future<void> _startReviewMode(BuildContext context) async {
    // 各モードの復習対象数を取得
    final requiredCount = await _statsRepository.getReviewCandidateCount(mode: 'required');
    final generalCount = await _statsRepository.getReviewCandidateCount(mode: 'general');
    final totalCount = requiredCount + generalCount;

    if (totalCount == 0) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('復習する問題がありません'),
          content: const Text('間違えた問題がないか、すでに復習済みです。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final mode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('復習する問題の種類を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              enabled: requiredCount > 0,
              leading: Icon(
                Icons.local_hospital,
                color: requiredCount > 0
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
              ),
              title: Text(
                '必修問題',
                style: TextStyle(
                  color: requiredCount > 0
                      ? null
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                ),
              ),
              trailing: Text(
                '$requiredCount問',
                style: TextStyle(
                  color: requiredCount > 0
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: requiredCount > 0 ? () => Navigator.pop(context, 'required') : null,
            ),
            ListTile(
              enabled: generalCount > 0,
              leading: Icon(
                Icons.menu_book,
                color: generalCount > 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
              ),
              title: Text(
                '一般・状況設定',
                style: TextStyle(
                  color: generalCount > 0
                      ? null
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                ),
              ),
              trailing: Text(
                '$generalCount問',
                style: TextStyle(
                  color: generalCount > 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: generalCount > 0 ? () => Navigator.pop(context, 'general') : null,
            ),
          ],
        ),
      ),
    );

    if (mode != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudyScreen.review(mode: mode),
        ),
      );
    }
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
              '評価ではなく、今の実力の目安を知るための測定です。\n'
              '複数分野から幅広く出題されます。\n'
              '後からいつでも実施できます。',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('後で')),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('今すぐ実施')),
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
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OnboardingExamScreen()));
    final updatedProfile = await userProfileRepository.fetchProfile();
    setState(() {
      _profile = updatedProfile;
      _homeTabKey = UniqueKey(); // ホームタブを再構築してスコアを更新
    });
  }

  /// ホームタブをリフレッシュ（学習履歴リセット後などに使用）
  void refreshHomeTab() {
    setState(() {
      _homeTabKey = UniqueKey();
    });
  }
}

class _MainActionCard extends StatelessWidget {
  const _MainActionCard({required this.needsOnboarding, required this.onStartOnboarding});

  final bool needsOnboarding;
  final VoidCallback onStartOnboarding;

  @override
  Widget build(BuildContext context) {
    if (!needsOnboarding) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '最初に実力を測定しましょう',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'ショート模試で現在地をチェックできます。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onStartOnboarding,
              icon: const Icon(Icons.play_arrow),
              label: const Text('初期スコア測定を開始'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DomainCategoryCard extends StatelessWidget {
  const _DomainCategoryCard({required this.title, required this.icon, required this.onTap});

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
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
