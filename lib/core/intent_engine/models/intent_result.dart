class IntentResult {
  final String intentId;
  final double confidence;
  final List<String> candidateActionIds;
  final List<dynamic> entities;
  final bool ambiguous;

  const IntentResult({
    required this.intentId,
    required this.confidence,
    required this.candidateActionIds,
    this.entities = const [],
    this.ambiguous = false,
  });
}