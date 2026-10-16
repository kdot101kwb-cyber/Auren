import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/business.dart';
import '../../../core/models/opportunity.dart';

class AurenLocalSnapshot {
  final String city, country;
  final List<AurenBusiness> businesses;
  final List<AurenOpportunity> opportunities;

  const AurenLocalSnapshot({
    required this.city,
    required this.country,
    required this.businesses,
    required this.opportunities,
  });
}

class AurenLocalIntelligenceService {
  final FirebaseFirestore db;

  AurenLocalIntelligenceService({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  /// Matches only the location fields the user supplied.
  ///
  /// When both city and country are supplied, both must match. This avoids
  /// blank stored fields matching an omitted filter and leaking unrelated
  /// businesses or opportunities into local results.
  static bool locationMatches({
    required String city,
    required String country,
    required String candidateCity,
    required String candidateCountry,
  }) {
    final requestedCity = city.trim().toLowerCase();
    final requestedCountry = country.trim().toLowerCase();
    if (requestedCity.isEmpty && requestedCountry.isEmpty) return false;

    final actualCity = candidateCity.trim().toLowerCase();
    final actualCountry = candidateCountry.trim().toLowerCase();

    final cityMatches =
        requestedCity.isEmpty || actualCity == requestedCity;
    final countryMatches =
        requestedCountry.isEmpty || actualCountry == requestedCountry;
    return cityMatches && countryMatches;
  }

  Stream<AurenLocalSnapshot> watch({
    required String city,
    required String country,
  }) {
    final c = city.trim();
    final co = country.trim();
    if (c.isEmpty && co.isEmpty) {
      return Stream.value(AurenLocalSnapshot(
        city: c,
        country: co,
        businesses: const [],
        opportunities: const [],
      ));
    }

    final businessQuery = db
        .collection('businesses')
        .where('visibility', isEqualTo: 'public')
        .limit(100)
        .snapshots();
    final opportunityQuery = db
        .collection('opportunities')
        .where('status', isEqualTo: 'open')
        .limit(100)
        .snapshots();

    return businessQuery.asyncMap((businessSnapshot) async {
      final opportunitySnapshot = await opportunityQuery.first;
      final businesses = businessSnapshot.docs
          .map((doc) => AurenBusiness.fromMap(doc.id, doc.data()))
          .where((business) => locationMatches(
                city: c,
                country: co,
                candidateCity: business.city,
                candidateCountry: business.country,
              ))
          .take(30)
          .toList();
      final opportunities = opportunitySnapshot.docs
          .map((doc) => AurenOpportunity.fromMap(doc.id, doc.data()))
          .where((opportunity) => locationMatches(
                city: c,
                country: co,
                candidateCity: opportunity.city,
                candidateCountry: opportunity.country,
              ))
          .take(30)
          .toList();
      return AurenLocalSnapshot(
        city: c,
        country: co,
        businesses: businesses,
        opportunities: opportunities,
      );
    });
  }
}
