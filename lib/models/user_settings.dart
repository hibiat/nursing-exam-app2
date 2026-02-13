import 'app_theme.dart';

/// ユーザー設定モデル
class UserSettings {
  const UserSettings({
    required this.timeLimitSeconds,
    this.showTimer = false,
    this.theme = AppTheme.light,
  });

  final int timeLimitSeconds;
  final bool showTimer;
  final AppTheme theme;

  factory UserSettings.fromFirestore(Map<String, dynamic> data, int defaultTimeLimitSeconds) {
    return UserSettings(
      timeLimitSeconds: data['timeLimitSeconds'] as int? ?? defaultTimeLimitSeconds,
      showTimer: data['showTimer'] as bool? ?? false,
      theme: AppTheme.fromStorage(data['theme'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'timeLimitSeconds': timeLimitSeconds,
      'showTimer': showTimer,
      'theme': theme.name,
    };
  }
}
