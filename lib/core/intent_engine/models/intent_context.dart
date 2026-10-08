class IntentContext {
  final String userId;
  final String input;
  final String? locale;
  final String? countryCode;
  final String? regionCode;
  final String? cityCode;
  final String? currencyCode;
  final Map<String, dynamic> metadata;

  const IntentContext({
    required this.userId,
    required this.input,
    this.locale,
    this.countryCode,
    this.regionCode,
    this.cityCode,
    this.currencyCode,
    this.metadata = const {},
  });
}