import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/transport/domain/mobility_models.dart';

void main() {
  group('PublicTransportRoute', () {
    test('does not publish a route without source evidence', () {
      final route = PublicTransportRoute(
        operator: 'Local operator',
        routeName: 'Route A',
        stops: ['Central', 'Market'],
        evidence: null,
      );
      expect(route.isPublishable, isFalse);
    });

    test('accepts route details only when source evidence is named', () {
      final route = PublicTransportRoute(
        operator: 'Operator',
        routeName: 'A1',
        stops: ['Central', 'Market'],
        evidence: MobilityEvidence(
          sourceName: 'Operator timetable',
          observedAt: DateTime.utc(2026, 10, 21),
        ),
      );
      expect(route.isPublishable, isTrue);
      expect(route.stops, ['Central', 'Market']);
    });
  });

  group('VehicleRecord', () {
    test('requires make, model and a plausible year', () {
      expect(
        const VehicleRecord(make: '', model: 'Sedan', year: 2020).isValid,
        isFalse,
      );
      expect(
        const VehicleRecord(make: 'A', model: 'Sedan', year: 2020).isValid,
        isTrue,
      );
    });

    test('flags expired insurance and overdue maintenance', () {
      final now = DateTime(2026, 10, 21);
      final vehicle = VehicleRecord(
        make: 'A',
        model: 'B',
        year: 2020,
        insuranceExpiresAt: DateTime(2026, 10, 20),
        maintenanceDueAt: DateTime(2026, 10, 1),
      );
      expect(vehicle.insuranceNeedsAttention(now), isTrue);
      expect(vehicle.maintenanceNeedsAttention(now), isTrue);
    });
  });

  group('MobilityCostEstimate', () {
    test('calculates fuel and total from explicit user inputs', () {
      const estimate = MobilityCostEstimate(
        distanceKm: 100,
        trips: 2,
        fuelLitresPer100Km: 8,
        fuelPricePerLitre: 1.5,
        tolls: 2,
        parking: 3,
        otherCosts: 1,
        currency: 'SDG',
      );
      expect(estimate.isValid, isTrue);
      expect(estimate.fuelCost, 24);
      expect(estimate.total, 36);
    });

    test('rejects estimates whose arithmetic overflows despite finite inputs', () {
      const estimate = MobilityCostEstimate(
        distanceKm: 1e308,
        trips: 2,
        fuelLitresPer100Km: 100,
        fuelPricePerLitre: 1e308,
        currency: 'SDG',
      );
      expect(estimate.distanceKm.isFinite, isTrue);
      expect(estimate.fuelPricePerLitre.isFinite, isTrue);
      expect(estimate.isValid, isFalse);
      expect(estimate.total.isFinite, isFalse);
    });

    test('rejects negative, non-finite and missing currency inputs', () {
      const negative = MobilityCostEstimate(
        distanceKm: 20,
        trips: 1,
        fuelLitresPer100Km: 5,
        fuelPricePerLitre: -1,
        currency: 'SDG',
      );
      const missingCurrency = MobilityCostEstimate(
        distanceKm: 20,
        trips: 1,
        fuelLitresPer100Km: 5,
        fuelPricePerLitre: 1,
        currency: ' ',
      );
      expect(negative.isValid, isFalse);
      expect(missingCurrency.isValid, isFalse);
    });
  });

  group('CargoShipment and PortInformation', () {
    test('requires shipment reference and both endpoints', () {
      expect(
        const CargoShipment(
          reference: 'C1',
          origin: 'Port A',
          destination: '',
          status: CargoStatus.draft,
        ).isValid,
        isFalse,
      );
    });

    test('does not present port information as sourced without evidence', () {
      expect(
        const PortInformation(
          portName: 'Port A',
          country: 'Country A',
          evidence: null,
        ).isPublishable,
        isFalse,
      );
    });
  });
}
