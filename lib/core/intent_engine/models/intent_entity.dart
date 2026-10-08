enum IntentEntityType { product, service, business, supplier, opportunity, profile, content, location, category, unknown }

class IntentEntity {
  final IntentEntityType type;
  final String value;
  final double confidence;
  const IntentEntity({required this.type, required this.value, this.confidence = 1.0});
}