class SkillProgress {
  const SkillProgress({
    required this.skillId,
    required this.label,
    required this.previousScore,
    required this.currentScore,
  });

  final String skillId;
  final String label;
  final double previousScore;
  final double currentScore;
}
