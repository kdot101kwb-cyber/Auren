import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/mobility_models.dart';

/// Small offline-first store for user-entered mobility records.
/// This is local device storage only; it does not sync or share data.
class MobilityLocalStore {
  MobilityLocalStore({SharedPreferences? preferences})
      : _preferences = preferences;

  static const _routesKey = 'auren_mobility_routes_v1';
  static const _vehiclesKey = 'auren_mobility_vehicles_v1';
  static const _shipmentsKey = 'auren_mobility_shipments_v1';
  static const _portsKey = 'auren_mobility_ports_v1';

  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> _read(String key) async {
    final values = (await _prefs).getStringList(key) ?? const <String>[];
    final records = <Map<String, dynamic>>[];
    for (final value in values) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          records.add(Map<String, dynamic>.from(decoded));
        }
      } on FormatException {
        // Skip a damaged record instead of preventing the rest from loading.
      } on TypeError {
        // Skip malformed data written by an older or interrupted version.
      }
    }
    return records;
  }

  Future<void> _write(String key, Iterable<Map<String, dynamic>> records) async {
    await (await _prefs).setStringList(
      key,
      records.map(jsonEncode).toList(growable: false),
    );
  }

  DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;

  MobilityEvidence? _evidence(Map<String, dynamic> json) {
    final source = json['sourceName'];
    final observedAt = _date(json['observedAt']);
    if (source is! String || observedAt == null) return null;
    return MobilityEvidence(
      sourceName: source,
      observedAt: observedAt,
      reference: json['reference'] as String?,
    );
  }

  Future<List<PublicTransportRoute>> loadRoutes() async {
    final result = <PublicTransportRoute>[];
    for (final json in await _read(_routesKey)) {
      try {
        final stops = json['stops'];
        if (json['operator'] is! String ||
            json['routeName'] is! String ||
            stops is! List) continue;
        result.add(PublicTransportRoute(
          operator: json['operator'] as String,
          routeName: json['routeName'] as String,
          stops: stops.whereType<String>().toList(),
          evidence: json['evidence'] is Map
              ? _evidence(Map<String, dynamic>.from(json['evidence'] as Map))
              : null,
        ));
      } on TypeError {
        continue;
      }
    }
    return result;
  }

  Future<void> saveRoutes(List<PublicTransportRoute> routes) => _write(
        _routesKey,
        routes.map((route) => {
          'operator': route.operator,
          'routeName': route.routeName,
          'stops': route.stops,
          'evidence': route.evidence == null ? null : {
            'sourceName': route.evidence!.sourceName,
            'observedAt': route.evidence!.observedAt.toIso8601String(),
            'reference': route.evidence!.reference,
          },
        }),
      );

  Future<List<VehicleRecord>> loadVehicles() async {
    final result = <VehicleRecord>[];
    for (final json in await _read(_vehiclesKey)) {
      try {
        final year = json['year'];
        if (json['make'] is! String ||
            json['model'] is! String ||
            year is! num) continue;
        result.add(VehicleRecord(
          make: json['make'] as String,
          model: json['model'] as String,
          year: year.toInt(),
          registrationId: json['registrationId'] as String?,
          insuranceExpiresAt: _date(json['insuranceExpiresAt']),
          maintenanceDueAt: _date(json['maintenanceDueAt']),
          notes: json['notes'] as String? ?? '',
        ));
      } on TypeError {
        continue;
      }
    }
    return result;
  }

  Future<void> saveVehicles(List<VehicleRecord> vehicles) => _write(
        _vehiclesKey,
        vehicles.map((vehicle) => {
          'make': vehicle.make,
          'model': vehicle.model,
          'year': vehicle.year,
          'registrationId': vehicle.registrationId,
          'insuranceExpiresAt': vehicle.insuranceExpiresAt?.toIso8601String(),
          'maintenanceDueAt': vehicle.maintenanceDueAt?.toIso8601String(),
          'notes': vehicle.notes,
        }),
      );

  Future<List<CargoShipment>> loadShipments() async {
    final result = <CargoShipment>[];
    for (final json in await _read(_shipmentsKey)) {
      try {
        final statusName = json['status'];
        final status = CargoStatus.values.where((item) => item.name == statusName);
        final requirements = json['deliveryRequirements'];
        if (json['reference'] is! String ||
            json['origin'] is! String ||
            json['destination'] is! String ||
            status.isEmpty) continue;
        result.add(CargoShipment(
          reference: json['reference'] as String,
          origin: json['origin'] as String,
          destination: json['destination'] as String,
          status: status.first,
          carrier: json['carrier'] as String?,
          deliveryRequirements: requirements is List
              ? requirements.whereType<String>().toList()
              : const [],
          notes: json['notes'] as String? ?? '',
        ));
      } on TypeError {
        continue;
      }
    }
    return result;
  }

  Future<void> saveShipments(List<CargoShipment> shipments) => _write(
        _shipmentsKey,
        shipments.map((shipment) => {
          'reference': shipment.reference,
          'origin': shipment.origin,
          'destination': shipment.destination,
          'status': shipment.status.name,
          'carrier': shipment.carrier,
          'deliveryRequirements': shipment.deliveryRequirements,
          'notes': shipment.notes,
        }),
      );

  Future<List<PortInformation>> loadPorts() async {
    final result = <PortInformation>[];
    for (final json in await _read(_portsKey)) {
      try {
        if (json['portName'] is! String || json['country'] is! String) continue;
        result.add(PortInformation(
          portName: json['portName'] as String,
          country: json['country'] as String,
          evidence: json['evidence'] is Map
              ? _evidence(Map<String, dynamic>.from(json['evidence'] as Map))
              : null,
          operationalNote: json['operationalNote'] as String? ?? '',
        ));
      } on TypeError {
        continue;
      }
    }
    return result;
  }

  Future<void> savePorts(List<PortInformation> ports) => _write(
        _portsKey,
        ports.map((port) => {
          'portName': port.portName,
          'country': port.country,
          'operationalNote': port.operationalNote,
          'evidence': port.evidence == null ? null : {
            'sourceName': port.evidence!.sourceName,
            'observedAt': port.evidence!.observedAt.toIso8601String(),
            'reference': port.evidence!.reference,
          },
        }),
      );
}
