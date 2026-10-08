class IntentContext {
  final String userId;
  final String input;
  final String? locale;
  final String? countryCode;
  final Map<String, dynamic> metadata;

  const IntentContext({
    required this.userId,
    required this.input,
    this.locale,
    this.countryCode,
    this.metadata = const {},
  });
}