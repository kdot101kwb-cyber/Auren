enum IntentEntityType {
  product,
  service,
  business,
  supplier,
  opportunity,
  profile,
  content,
  location,
  country,
  region,
  city,
  category,
  market,
  currency,
  shippingRoute,
  unknown,
}

class IntentEntity {
  final IntentEntityType type;
  final String value;
  final double confidence;
  final Map<String, dynamic> metadata;

  const IntentEntity({
    required this.type,
    required this.value,
    this.confidence = 1.0,
    this.metadata = const {},
  });
}