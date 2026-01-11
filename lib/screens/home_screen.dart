import 'package:flutter/material.dart';

import 'select_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final user = await AuthService.ensureSignedIn();
    // ignore: avoid_print
    print('Signed in uid=${user.uid}');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('看護師国家試験アプリ'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '必修'),
              Tab(text: '一般・状況設定'),
            ],
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
  }
}
