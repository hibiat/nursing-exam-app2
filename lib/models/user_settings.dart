class UserSettings {
  const UserSettings({required this.timeLimitSeconds});

  final int timeLimitSeconds;

  factory UserSettings.fromFirestore(Map<String, dynamic> data, int fallbackSeconds) {
    return UserSettings(
      timeLimitSeconds: (data['timeLimitSeconds'] as num?)?.toInt() ?? fallbackSeconds,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'timeLimitSeconds': timeLimitSeconds,
    };
  }
}
