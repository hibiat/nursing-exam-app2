class StudySessionState {
  const StudySessionState({
    required this.mode,
    required this.domainId,
    required this.subdomainId,
    required this.unitCount,
    required this.unitTarget,
  });

  final String mode;
  final String? domainId;
  final String? subdomainId;
  final int unitCount;
  final int unitTarget;

  StudySessionState copyWith({
    String? mode,
    String? domainId,
    String? subdomainId,
    int? unitCount,
    int? unitTarget,
  }) {
    return StudySessionState(
      mode: mode ?? this.mode,
      domainId: domainId ?? this.domainId,
      subdomainId: subdomainId ?? this.subdomainId,
      unitCount: unitCount ?? this.unitCount,
      unitTarget: unitTarget ?? this.unitTarget,
    );
  }
}
