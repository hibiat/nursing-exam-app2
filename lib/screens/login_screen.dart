import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// ログイン画面
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.signInWithGoogle();
      // 認証状態の変更はStreamBuilderで検知される
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Google認証に失敗しました: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.signInWithApple();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Apple認証に失敗しました: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithDemo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.signInWithDemo();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'デモ認証に失敗しました: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
              // アプリロゴとタイトル
              Icon(
                Icons.local_hospital,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '看護師国家試験アプリ',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'ログインして学習を始めましょう',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Google Sign-In ボタン
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Googleでログイン'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Apple Sign-In ボタン（iOS/macOSのみ表示）
              if (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS) ...[
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithApple,
                  icon: const Icon(Icons.apple, size: 28),
                  label: const Text('Appleでログイン'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // デモアカウントボタン（デバッグ時のみ）
              if (kDebugMode) ...[
                TextButton.icon(
                  onPressed: _isLoading ? null : _signInWithDemo,
                  icon: const Icon(Icons.science),
                  label: const Text('デモアカウント（デバッグ用）'),
                ),
                const SizedBox(height: 16),
              ],

              // エラーメッセージ
              if (_errorMessage != null) ...[
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ローディング
              if (_isLoading) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 40),

              // 利用規約とプライバシーポリシー
              Text(
                'ログインすることで、利用規約とプライバシーポリシーに同意したものとみなされます。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
