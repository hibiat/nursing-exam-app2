import 'package:flutter/material.dart';

import '../models/user_settings.dart';
import '../repositories/user_settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserSettingsRepository repository = UserSettingsRepository();
  late Future<UserSettings> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = repository.fetchSettings();
  }

  Future<void> _updateTimeLimit(int seconds) async {
    final updated = UserSettings(timeLimitSeconds: seconds);
    await repository.saveSettings(updated);
    setState(() {
      _settingsFuture = Future.value(updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: FutureBuilder<UserSettings>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('設定の読み込みに失敗しました'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() {
                      _settingsFuture = repository.fetchSettings();
                    }),
                    child: const Text('再試行'),
                  ),
                ],
              ),
            );
          }
          final settings = snapshot.data ??
              const UserSettings(
                timeLimitSeconds: UserSettingsRepository.defaultTimeLimitSeconds,
              );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('1問あたりの制限時間', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...[60, 90, 120].map(
                (seconds) => RadioListTile<int>(
                  title: Text('${seconds}秒'),
                  value: seconds,
                  groupValue: settings.timeLimitSeconds,
                  onChanged: (value) {
                    if (value == null) return;
                    _updateTimeLimit(value);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '※ 国試の制限時間・問題数から妥当な秒数を後で調整可能です。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
