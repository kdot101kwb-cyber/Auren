import 'package:flutter/foundation.dart';

/// Provenance for externally sourced mobility information.
/// No source means the record must not be presented as verified/live.
@immutable
class MobilityEvidence {
  const MobilityEvidence({
    required this.sourceName,
    required this.observedAt,
    this.reference,
  });

  final String sourceName;
  final DateTime observedAt;
  final String? reference;

  bool get isCredible => sourceName.trim().isNotEmpty;
}

@immutable
class PublicTransportRoute {
  PublicTransportRoute({
    required this.operator,
    required this.routeName,
    required List<String> stops,
    required this.evidence,
  }) : stops = List.unmodifiable(stops.map((s) => s.trim()).where((s) => s.isNotEmpty));

  final String operator;
  final String routeName;
  final List<String> stops;
  final MobilityEvidence? evidence;

  bool get isPublishable =>
      operator.trim().isNotEmpty &&
      routeName.trim().isNotEmpty &&
      stops.isNotEmpty &&
      evidence?.isCredible == true;
}

@immutable
class VehicleRecord {
  const VehicleRecord({
    required this.make,
    required this.model,
    required this.year,
    this.registrationId,
    this.insuranceExpiresAt,
    this.maintenanceDueAt,
    this.notes = '',
  });

  final String make;
  final String model;
  final int year;
  final String? registrationId;
  final DateTime? insuranceExpiresAt;
  final DateTime? maintenanceDueAt;
  final String notes;

  bool get isValid =>
      make.trim().isNotEmpty &&
      model.trim().isNotEmpty &&
      year >= 1886 &&
      year <= DateTime.now().year + 1;

  bool insuranceNeedsAttention(DateTime now) =>
      insuranceExpiresAt != null &&
      !insuranceExpiresAt!.isAfter(now.add(const Duration(days: 30)));

  bool maintenanceNeedsAttention(DateTime now) =>
      maintenanceDueAt != null && !maintenanceDueAt!.isAfter(now);
}

@immutable
class MobilityCostEstimate {
  const MobilityCostEstimate({
    required this.distanceKm,
    required this.trips,
    required this.fuelLitresPer100Km,
    required this.fuelPricePerLitre,
    this.tolls = 0,
    this.parking = 0,
    this.otherCosts = 0,
    required this.currency,
  });

  final double distanceKm;
  final int trips;
  final double fuelLitresPer100Km;
  final double fuelPricePerLitre;
  final double tolls;
  final double parking;
  final double otherCosts;
  final String currency;

  bool get isValid =>
      distanceKm.isFinite &&
      distanceKm > 0 &&
      trips > 0 &&
      fuelLitresPer100Km.isFinite &&
      fuelLitresPer100Km >= 0 &&
      fuelPricePerLitre.isFinite &&
      fuelPricePerLitre >= 0 &&
      tolls.isFinite &&
      tolls >= 0 &&
      parking.isFinite &&
      parking >= 0 &&
      otherCosts.isFinite &&
      otherCosts >= 0 &&
      currency.trim().isNotEmpty;

  double get fuelCost =>
      distanceKm * trips * fuelLitresPer100Km / 100 * fuelPricePerLitre;

  double get total => fuelCost + (tolls + parking + otherCosts) * trips;
}

enum CargoStatus {
  draft,
  prepared,
  inTransit,
  delayed,
  delivered,
  cancelled,
}

@immutable
class CargoShipment {
  const CargoShipment({
    required this.reference,
    required this.origin,
    required this.destination,
    required this.status,
    this.carrier,
    this.deliveryRequirements = const [],
    this.notes = '',
  });

  final String reference;
  final String origin;
  final String destination;
  final String? carrier;
  final CargoStatus status;
  final List<String> deliveryRequirements;
  final String notes;

  bool get isValid =>
      reference.trim().isNotEmpty &&
      origin.trim().isNotEmpty &&
      destination.trim().isNotEmpty;
}

@immutable
class PortInformation {
  const PortInformation({
    required this.portName,
    required this.country,
    required this.evidence,
    this.operationalNote = '',
  });

  final String portName;
  final String country;
  final MobilityEvidence? evidence;
  final String operationalNote;

  bool get isPublishable =>
      portName.trim().isNotEmpty &&
      country.trim().isNotEmpty &&
      evidence?.isCredible == true;
}
