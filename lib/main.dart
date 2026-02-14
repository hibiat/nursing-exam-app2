import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NursingExamApp());
}

class NursingExamApp extends StatefulWidget {
  const NursingExamApp({super.key});

  @override
  State<NursingExamApp> createState() => _NursingExamAppState();
}

class _NursingExamAppState extends State<NursingExamApp> {
  final ThemeService _themeService = ThemeService();
  late final Future<void> _themeLoadFuture;

  @override
  void initState() {
    super.initState();
    _themeLoadFuture = _themeService.loadFromSettings();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _themeLoadFuture,
      builder: (context, _) {
        return AnimatedBuilder(
          animation: _themeService,
          builder: (context, child) {
            return MaterialApp(
              title: 'Nursing Exam App',
              theme: _themeService.themeData,
              home: BootstrapScreen(themeService: _themeService),
            );
          },
        );
      },
    );
  }
}

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key, required this.themeService});

  final ThemeService themeService;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: FirebaseService.instance
          .initialize()
          .timeout(const Duration(seconds: 3), onTimeout: () {}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 認証状態を監視
        return StreamBuilder<dynamic>(
          stream: AuthService.authStateChanges,
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // 未ログイン → LoginScreen
            if (authSnapshot.data == null) {
              return const LoginScreen();
            }

            // ログイン済み → HomeScreen
            return HomeScreen(themeService: themeService);
          },
        );
      },
    );
  }
}
