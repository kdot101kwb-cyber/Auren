import 'dart:async';

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

  /// Emits whenever either input stream changes, after both have emitted once.
  ///
  /// Both subscriptions are cancelled when the returned stream is cancelled.
  static Stream<(A, B)> combineLatest2<A, B>(
    Stream<A> first,
    Stream<B> second,
  ) {
    late StreamController<(A, B)> controller;
    StreamSubscription<A>? firstSubscription;
    StreamSubscription<B>? secondSubscription;
    A? latestFirst;
    B? latestSecond;
    var hasFirst = false;
    var hasSecond = false;
    var firstDone = false;
    var secondDone = false;
    var closing = false;

    void emitIfReady() {
      if (hasFirst && hasSecond && !controller.isClosed) {
        controller.add((latestFirst as A, latestSecond as B));
      }
    }

    Future<void> closeIfDone() async {
      final sourceCannotProducePair =
          (firstDone && !hasFirst) || (secondDone && !hasSecond);
      if (closing ||
          controller.isClosed ||
          !(sourceCannotProducePair || (firstDone && secondDone))) {
        return;
      }

      closing = true;
      if (firstDone && !hasFirst) {
        await secondSubscription?.cancel();
      }
      if (secondDone && !hasSecond) {
        await firstSubscription?.cancel();
      }
      await controller.close();
    }

    controller = StreamController<(A, B)>(
      onListen: () {
        firstSubscription = first.listen(
          (value) {
            latestFirst = value;
            hasFirst = true;
            emitIfReady();
          },
          onError: controller.addError,
          onDone: () {
            firstDone = true;
            closeIfDone();
          },
        );
        secondSubscription = second.listen(
          (value) {
            latestSecond = value;
            hasSecond = true;
            emitIfReady();
          },
          onError: controller.addError,
          onDone: () {
            secondDone = true;
            closeIfDone();
          },
        );
      },
      onCancel: () async {
        await firstSubscription?.cancel();
        await secondSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  /// Matches only location fields supplied by the user.
  /// If both city and country are supplied, both must match.
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

    return combineLatest2(businessQuery, opportunityQuery).map((snapshots) {
      final (businessSnapshot, opportunitySnapshot) = snapshots;
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
