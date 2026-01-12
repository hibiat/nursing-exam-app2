import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../repositories/user_profile_repository.dart';
import '../widgets/score_summary_card.dart';
import 'onboarding_exam_screen.dart';
import 'select_screen.dart';
import 'settings_screen.dart';
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
    // ignore: avoid_print
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
                if (!(_profile?.onboardingCompleted ?? false))
                  TextButton(
                    onPressed: _startOnboardingExam,
                    child: const Text('ショート模試'),
                  ),
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(200),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScoreSummaryCard(
                      onStartOnboarding:
                          _profile?.onboardingCompleted == true ? null : _startOnboardingExam,
                    ),
                    const TabBar(
                      tabs: [
                        Tab(text: '必修'),
                        Tab(text: '一般・状況設定'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            body: const TabBarView(
              children: [
                SelectScreen(mode: 'required'),
                SelectScreen(mode: 'general'),
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
            title: const Text('ショート模試に挑戦しますか？'),
            content: const Text('10問ほど解いて、初期スコアを推定します。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('後で'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('今すぐ挑戦'),
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
