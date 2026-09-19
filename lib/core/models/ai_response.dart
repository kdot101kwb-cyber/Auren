class AurenAiResponse {
  final String text;
  final String? action;
  final Map<String, dynamic> payload;
  final bool requiresApproval;

  const AurenAiResponse({
    required this.text,
    this.action,
    this.payload = const {},
    this.requiresApproval = false,
  });
}
