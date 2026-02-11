import 'package:flutter/material.dart';

import '../models/app_theme.dart';
import '../models/user_settings.dart';
import '../repositories/user_settings_repository.dart';
import '../services/theme_service.dart';
import '../utils/user_friendly_error_messages.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.themeService});

  final ThemeService themeService;

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
      theme: currentSettings.theme,
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
      theme: currentSettings.theme,
    );
    await repository.saveSettings(updated);
    setState(() {
      _settingsFuture = Future.value(updated);
    });
  }

  Future<void> _updateTheme(AppTheme theme) async {
    final currentSettings = await _settingsFuture;
    final updated = UserSettings(
      timeLimitSeconds: currentSettings.timeLimitSeconds,
      showTimer: currentSettings.showTimer,
      theme: theme,
    );
    await repository.saveSettings(updated);
    widget.themeService.changeTheme(theme);
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
                  Text(UserFriendlyErrorMessages.getErrorMessage(snapshot.error)),
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
                showTimer: false,
              );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('テーマ', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ...AppTheme.values.map(
                        (theme) => RadioListTile<AppTheme>(
                          title: Text(theme.displayName),
                          value: theme,
                          groupValue: settings.theme,
                          onChanged: (value) {
                            if (value == null) return;
                            _updateTheme(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('タイマー表示', style: Theme.of(context).textTheme.titleMedium),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1問あたりの制限時間', style: Theme.of(context).textTheme.titleMedium),
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
                          subtitle: seconds == 90 ? const Text('推奨: 国試の平均時間') : null,
                          value: seconds,
                          groupValue: settings.timeLimitSeconds,
                          onChanged: settings.showTimer
                              ? (value) {
                                  if (value == null) return;
                                  _updateTimeLimit(value);
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
