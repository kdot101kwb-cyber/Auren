class AurenAiResponse {
  final String text;
  final String? action;
  final bool requiresApproval;

  const AurenAiResponse({
    required this.text,
    this.action,
    this.requiresApproval = false,
  });
}
