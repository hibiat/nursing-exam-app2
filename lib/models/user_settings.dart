/// ユーザー設定モデル
class UserSettings {
  const UserSettings({
    required this.timeLimitSeconds,
    this.showTimer = false,
  });

  final int timeLimitSeconds;
  final bool showTimer;

  factory UserSettings.fromFirestore(Map<String, dynamic> data, int defaultTimeLimitSeconds) {
    return UserSettings(
      timeLimitSeconds: data['timeLimitSeconds'] as int? ?? defaultTimeLimitSeconds,
      showTimer: data['showTimer'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'timeLimitSeconds': timeLimitSeconds,
      'showTimer': showTimer,
    };
  }
}