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
    final currentSettings = await _settingsFuture;
    final updated = UserSettings(
      timeLimitSeconds: seconds,
      showTimer: currentSettings.showTimer,
    );
    await repository.saveSettings(updated);
    setState(() {
      _settingsFuture = Future.value(updated);
    });
  }

  Future<void> _updateShowTimer(bool show) async {
    final currentSettings = await _settingsFuture;
    final updated = UserSettings(
      timeLimitSeconds: currentSettings.timeLimitSeconds,
      showTimer: show,
    );
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
                showTimer: false, // デフォルトは非表示
              );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // タイマー表示設定(新規)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'タイマー表示',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '本番を意識した学習をしたい場合にONにしてください',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('タイマーを表示する(本番モード)'),
                        subtitle: const Text('時間を意識した学習ができます'),
                        value: settings.showTimer,
                        onChanged: _updateShowTimer,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 制限時間設定
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1問あたりの制限時間',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'タイマー表示がONの時のみ有効です',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...[60, 90, 120].map(
                        (seconds) => RadioListTile<int>(
                          title: Text('${seconds}秒'),
                          subtitle: seconds == 90
                              ? const Text('推奨: 国試の平均時間')
                              : null,
                          value: seconds,
                          groupValue: settings.timeLimitSeconds,
                          onChanged: settings.showTimer
                              ? (value) {
                                  if (value == null) return;
                                  _updateTimeLimit(value);
                                }
                              : null, // タイマーOFFの時は変更不可
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '※ 国試の制限時間は問題数から逆算した秒数です。後で調整可能です。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}