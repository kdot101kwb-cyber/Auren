class MatchPlan {
  final String intentId;
  final List<String> candidateIds;
  final List<String> actionIds;
  final bool requiresHumanApproval;

  const MatchPlan({
    required this.intentId,
    this.candidateIds = const [],
    this.actionIds = const [],
    this.requiresHumanApproval = true,
  });
}
