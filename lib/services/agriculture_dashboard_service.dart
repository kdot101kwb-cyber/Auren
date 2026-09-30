import 'package:cloud_functions/cloud_functions.dart';

class AgricultureDashboardService {
  AgricultureDashboardService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> load({
    String crop = 'Sorghum',
    String iso3 = '',
    String country = '',
    int limit = 500,
  }) async {
    final callable =
        _functions.httpsCallable('aurenAgriAgricultureDashboard');
    final result = await callable.call(<String, dynamic>{
      'crop': crop,
      'iso3': iso3,
      'country': country,
      'limit': limit,
    });

    final raw = result.data;
    if (raw is! Map) {
      throw StateError('AUREN agriculture dashboard returned an invalid payload.');
    }

    return Map<String, dynamic>.from(raw);
  }
}
