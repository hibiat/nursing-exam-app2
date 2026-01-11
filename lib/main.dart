import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.instance.initialize();
  runApp(const NursingExamApp());
}

class NursingExamApp extends StatelessWidget {
  const NursingExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nursing Exam App',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
