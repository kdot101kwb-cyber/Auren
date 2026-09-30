import 'package:cloud_functions/cloud_functions.dart';

class GaezCropInsight {
  final String id;
  final String country;
  final String crop;
  final Map<String, dynamic> row;
  final String source;
  final String version;
  final String? resourceUrl;

  const GaezCropInsight({
    required this.id,
    required this.country,
    required this.crop,
    required this.row,
    required this.source,
    required this.version,
    required this.resourceUrl,
  });

  factory GaezCropInsight.fromMap(Map<String, dynamic> map) {
    return GaezCropInsight(
      id: '\${map['id'] ?? ''}',
      country: '\${map['country'] ?? ''}',
      crop: '\${map['crop'] ?? ''}',
      row: Map<String, dynamic>.from(map['row'] is Map ? map['row'] as Map : const {}),
      source: '\${map['source'] ?? 'FAO GAEZ v5 Crop Summary Data'}',
      version: '\${map['version'] ?? 'GAEZ v5'}',
      resourceUrl: map['resourceUrl']?.toString(),
    );
  }
}

class GaezCropInsightsService {
  final FirebaseFunctions functions;

  GaezCropInsightsService({FirebaseFunctions? functions})
      : functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<List<GaezCropInsight>> query({
    required String country,
    required String crop,
    String climateSource = '',
    String ssp = '',
    String period = '',
    String waterSupply = '',
    String management = '',
  }) async {
    final callable = functions.httpsCallable('aurenGaezCropInsights');
    final result = await callable.call({
      'country': country.trim(),
      'crop': crop.trim(),
      'climateSource': climateSource.trim(),
      'ssp': ssp.trim(),
      'period': period.trim(),
      'waterSupply': waterSupply.trim(),
      'management': management.trim(),
      'limit': 50,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final rows = data['rows'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((row) => GaezCropInsight.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }
}
