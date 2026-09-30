import 'package:cloud_functions/cloud_functions.dart';

class AgricultureProductionPoint {
  final String iso3;
  final String country;
  final String item;
  final int year;
  final double? production;
  final double? yieldValue;
  final double? area;
  final String unit;

  const AgricultureProductionPoint({
    required this.iso3,
    required this.country,
    required this.item,
    required this.year,
    this.production,
    this.yieldValue,
    this.area,
    this.unit = '',
  });

  factory AgricultureProductionPoint.fromMap(Map<dynamic, dynamic> m) {
    double? n(dynamic v) => v == null ? null : double.tryParse(v.toString());
    return AgricultureProductionPoint(
      iso3: (m['iso3'] ?? '').toString(),
      country: (m['country'] ?? '').toString(),
      item: (m['item'] ?? '').toString(),
      year: int.tryParse((m['year'] ?? 0).toString()) ?? 0,
      production: n(m['production']),
      yieldValue: n(m['yieldValue']),
      area: n(m['area']),
      unit: (m['unit'] ?? '').toString(),
    );
  }
}

class AgricultureForecastPoint {
  final int year;
  final double predictedProduction;
  final String method;

  const AgricultureForecastPoint({
    required this.year,
    required this.predictedProduction,
    required this.method,
  });

  factory AgricultureForecastPoint.fromMap(Map<dynamic, dynamic> m) {
    return AgricultureForecastPoint(
      year: int.tryParse((m['year'] ?? 0).toString()) ?? 0,
      predictedProduction: double.tryParse((m['predictedProduction'] ?? 0).toString()) ?? 0,
      method: (m['method'] ?? '').toString(),
    );
  }
}

class AgricultureProductionIntelligenceService {
  final FirebaseFunctions _functions;

  AgricultureProductionIntelligenceService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<List<AgricultureProductionPoint>> history({
    String? iso3,
    String? item,
    int? fromYear,
    int? toYear,
  }) async {
    final result = await _functions.httpsCallable('aurenAgriProductionHistory').call({
      'iso3': iso3,
      'item': item,
      'fromYear': fromYear,
      'toYear': toYear,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final rows = (data['rows'] as List? ?? const []);
    return rows.map((e) => AgricultureProductionPoint.fromMap(Map<dynamic, dynamic>.from(e as Map))).toList();
  }

  Future<List<AgricultureForecastPoint>> forecast({
    String? iso3,
    String? item,
    int horizon = 5,
  }) async {
    final result = await _functions.httpsCallable('aurenAgriProductionForecast').call({
      'iso3': iso3,
      'item': item,
      'horizon': horizon,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final rows = (data['forecast'] as List? ?? const []);
    return rows.map((e) => AgricultureForecastPoint.fromMap(Map<dynamic, dynamic>.from(e as Map))).toList();
  }

  Future<Map<String, dynamic>> seasonComparison({
    String? iso3,
    String? item,
  }) async {
    final result = await _functions.httpsCallable('aurenAgriSeasonComparison').call({
      'iso3': iso3,
      'item': item,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> cropScenario({
    required double baseProduction,
    double yieldChangePct = 0,
    double areaChangePct = 0,
    double priceChangePct = 0,
    double costChangePct = 0,
    String? iso3,
    String? item,
  }) async {
    final result = await _functions.httpsCallable('aurenAgriCropScenario').call({
      'iso3': iso3,
      'item': item,
      'baseProduction': baseProduction,
      'yieldChangePct': yieldChangePct,
      'areaChangePct': areaChangePct,
      'priceChangePct': priceChangePct,
      'costChangePct': costChangePct,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
