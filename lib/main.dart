import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/firebase_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NursingExamApp());
}

class NursingExamApp extends StatelessWidget {
  const NursingExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nursing Exam App',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const BootstrapScreen(),
    );
  }
}

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

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
        return const HomeScreen();
      },
    );
  }
}
