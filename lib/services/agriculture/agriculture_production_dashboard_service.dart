import 'package:cloud_functions/cloud_functions.dart';

class AgricultureProductionDashboardService {
  final FirebaseFunctions _functions;
  AgricultureProductionDashboardService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<Map<String, dynamic>> load({
    required String iso3,
    required String crop,
  }) async {
    final result = await _functions
        .httpsCallable('aurenAgriProductionIntelligence')
        .call({'iso3': iso3, 'crop': crop});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<List<Map<String, dynamic>>> forecast({
    required String iso3,
    required String crop,
    int horizon = 5,
  }) async {
    final result = await _functions
        .httpsCallable('aurenAgriProductionForecast')
        .call({'iso3': iso3, 'item': crop, 'horizon': horizon});
    final data = Map<String, dynamic>.from(result.data as Map);
    return (data['forecast'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> scenario({
    required String iso3,
    required String crop,
    required double baseProduction,
    double yieldChangePct = 0,
    double areaChangePct = 0,
    double priceChangePct = 0,
    double costChangePct = 0,
  }) async {
    final result = await _functions
        .httpsCallable('aurenAgriCropScenario')
        .call({
      'iso3': iso3,
      'item': crop,
      'baseProduction': baseProduction,
      'yieldChangePct': yieldChangePct,
      'areaChangePct': areaChangePct,
      'priceChangePct': priceChangePct,
      'costChangePct': costChangePct,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
