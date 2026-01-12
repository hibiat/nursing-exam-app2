class UserProfile {
  const UserProfile({
    required this.onboardingCompleted,
    required this.onboardingPromptedAt,
    required this.onboardingCompletedAt,
  });

  final bool onboardingCompleted;
  final DateTime? onboardingPromptedAt;
  final DateTime? onboardingCompletedAt;

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    final promptedRaw = data['onboardingPromptedAt'];
    final completedRaw = data['onboardingCompletedAt'];
    final promptedAt = promptedRaw is DateTime
        ? promptedRaw
        : (promptedRaw as dynamic?)?.toDate() as DateTime?;
    final completedAt = completedRaw is DateTime
        ? completedRaw
        : (completedRaw as dynamic?)?.toDate() as DateTime?;
    return UserProfile(
      onboardingCompleted: (data['onboardingCompleted'] as bool?) ?? false,
      onboardingPromptedAt: promptedAt,
      onboardingCompletedAt: completedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'onboardingCompleted': onboardingCompleted,
      'onboardingPromptedAt': onboardingPromptedAt,
      'onboardingCompletedAt': onboardingCompletedAt,
    };
  }
}
