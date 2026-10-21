import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/features/transport/data/mobility_local_store.dart';
import 'package:auren/features/transport/domain/mobility_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('round-trips transit routes and source evidence offline', () async {
    final store = MobilityLocalStore();
    final route = PublicTransportRoute(
      operator: 'Operator',
      routeName: 'R1',
      stops: ['Central', 'Market'],
      evidence: MobilityEvidence(
        sourceName: 'Operator website',
        observedAt: DateTime.utc(2026, 10, 21),
        reference: 'https://example.invalid/routes/r1',
      ),
    );

    await store.saveRoutes([route]);
    final loaded = await MobilityLocalStore().loadRoutes();

    expect(loaded, hasLength(1));
    expect(loaded.single.stops, ['Central', 'Market']);
    expect(loaded.single.evidence?.sourceName, 'Operator website');
    expect(loaded.single.isPublishable, isTrue);
  });

  test('round-trips vehicle dates and shipment status/requirements', () async {
    final store = MobilityLocalStore();
    await store.saveVehicles([
      VehicleRecord(
        make: 'Toyota',
        model: 'Corolla',
        year: 2020,
        insuranceExpiresAt: DateTime(2027, 1, 2),
        maintenanceDueAt: DateTime(2026, 12, 1),
      ),
    ]);
    await store.saveShipments([
      const CargoShipment(
        reference: 'C-101',
        origin: 'Port Sudan',
        destination: 'Khartoum',
        status: CargoStatus.inTransit,
        deliveryRequirements: ['Packaging', 'Receiver signature'],
        notes: 'Fragile',
      ),
    ]);

    final vehicle = (await MobilityLocalStore().loadVehicles()).single;
    final shipment = (await MobilityLocalStore().loadShipments()).single;

    expect(vehicle.insuranceExpiresAt, DateTime(2027, 1, 2));
    expect(vehicle.maintenanceDueAt, DateTime(2026, 12, 1));
    expect(shipment.status, CargoStatus.inTransit);
    expect(shipment.deliveryRequirements, ['Packaging', 'Receiver signature']);
    expect(shipment.notes, 'Fragile');
  });

  test('round-trips port source evidence and tolerates damaged entries', () async {
    final store = MobilityLocalStore();
    await store.savePorts([
      PortInformation(
        portName: 'Port Sudan',
        country: 'Sudan',
        evidence: MobilityEvidence(
          sourceName: 'Port authority',
          observedAt: DateTime.utc(2026, 10, 21),
        ),
      ),
    ]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('auren_mobility_ports_v1', [
      '{bad json',
      '{"portName":"Port Sudan","country":"Sudan","evidence":null}',
    ]);

    final loaded = await MobilityLocalStore().loadPorts();
    expect(loaded, hasLength(1));
    expect(loaded.single.evidence, isNull);
    expect(loaded.single.isPublishable, isFalse);
  });
}
