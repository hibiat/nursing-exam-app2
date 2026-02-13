import 'package:flutter/material.dart';

import '../models/app_theme.dart';
import '../models/user_settings.dart';
import '../repositories/user_settings_repository.dart';
import '../services/theme_service.dart';
import '../services/learning_history_reset_service.dart';
import '../utils/user_friendly_error_messages.dart';
import '../widgets/source_attribution_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.themeService});

  final ThemeService themeService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserSettingsRepository repository = UserSettingsRepository();
  final LearningHistoryResetService resetService = LearningHistoryResetService();
  late Future<UserSettings> _settingsFuture;
  final TextEditingController _customSecondsController = TextEditingController();

  static const List<int> _presetSeconds = [60, 80, 120];

  @override
  void initState() {
    super.initState();
    _settingsFuture = repository.fetchSettings();
  }

  @override
  void dispose() {
    _customSecondsController.dispose();
    super.dispose();
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


  Future<void> _resetLearningHistory() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('学習履歴をリセット'),
        content: const Text(
          '学習履歴を削除して、初回模試から始まる状態に戻します。\nこの操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('リセットする'),
          ),
        ],
      ),
    );

    if (shouldReset != true) return;

    await resetService.resetAllLearningHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('学習履歴をリセットしました')),
    );
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
          final isCustomTime = !_presetSeconds.contains(settings.timeLimitSeconds);
          if (isCustomTime && _customSecondsController.text != '${settings.timeLimitSeconds}') {
            _customSecondsController.text = '${settings.timeLimitSeconds}';
          }
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
                      ..._presetSeconds.map(
                        (seconds) => RadioListTile<int>(
                          title: Text('${seconds}秒'),
                          subtitle: seconds == 80 ? const Text('推奨: 本番に近い設定') : null,
                          value: seconds,
                          groupValue: isCustomTime ? -1 : settings.timeLimitSeconds,
                          onChanged: settings.showTimer
                              ? (value) {
                                  if (value == null) return;
                                  _updateTimeLimit(value);
                                }
                              : null,
                        ),
                      ),
                      RadioListTile<int>(
                        title: const Text('カスタム'),
                        subtitle: const Text('自由に秒数を設定'),
                        value: -1,
                        groupValue: isCustomTime ? -1 : settings.timeLimitSeconds,
                        onChanged: settings.showTimer
                            ? (_) {
                                final parsed = int.tryParse(_customSecondsController.text);
                                if (parsed != null && parsed > 0) {
                                  _updateTimeLimit(parsed);
                                }
                              }
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _customSecondsController,
                          keyboardType: TextInputType.number,
                          enabled: settings.showTimer,
                          decoration: const InputDecoration(
                            labelText: 'カスタム秒数',
                            suffixText: '秒',
                          ),
                          onSubmitted: (value) {
                            final parsed = int.tryParse(value);
                            if (parsed != null && parsed > 0) {
                              _updateTimeLimit(parsed);
                            }
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
                      Text('学習履歴', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        '履歴を削除して初回模試から再スタートします。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: _resetLearningHistory,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('学習履歴をリセット'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SourceAttributionSection(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
