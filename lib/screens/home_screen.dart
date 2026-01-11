import 'package:flutter/material.dart';

import 'select_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
