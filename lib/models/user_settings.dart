class UserSettings {
  const UserSettings({
    required this.timeLimitSeconds,
    this.showTimer = false,
  });

  final int timeLimitSeconds;
  final bool showTimer;

  // Firestoreからの読み込み用
  factory UserSettings.fromFirestore(Map<String, dynamic> data, int defaultTimeLimitSeconds) {
    return UserSettings(
      timeLimitSeconds: data['timeLimitSeconds'] as int? ?? defaultTimeLimitSeconds,
      showTimer: data['showTimer'] as bool? ?? false,
    );
  }

  // JSON形式での読み込み(互換性のため残す)
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      timeLimitSeconds: json['timeLimitSeconds'] as int? ?? 90,
      showTimer: json['showTimer'] as bool? ?? false,
    );
  }

  // Firestoreへの保存用
  Map<String, dynamic> toFirestore() {
    return {
      'timeLimitSeconds': timeLimitSeconds,
      'showTimer': showTimer,
    };
  }

  // JSON形式での保存(互換性のため残す)
  Map<String, dynamic> toJson() {
    return {
      'timeLimitSeconds': timeLimitSeconds,
      'showTimer': showTimer,
    };
  }
}