import '../../intent_engine/models/intent_entity.dart';

class MatchRequest {
  final String userId;
  final String query;
  final String? countryCode;
  final String? currencyCode;
  final List<IntentEntity> entities;

  const MatchRequest({
    required this.userId,
    required this.query,
    this.countryCode,
    this.currencyCode,
    this.entities = const [],
  });
}
