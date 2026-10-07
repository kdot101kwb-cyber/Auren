import 'dart:convert';

import 'package:http/http.dart' as http;

class AurenGaezV5Service {
  static const String readmeUrl =
      'https://data.apps.fao.org/catalog/dataset/514c92d5-9e01-4c70-814a-80ea1ca9fe6a/resource/768b08ad-be9c-427a-84be-3a3d6dd7835a/download/_readme_res05.xlsx';

  static const String officialRes05Url =
      'https://gaez-services.fao.org/server/rest/services/res05/ImageServer';

  static const String officialRasterBaseUrl =
      'https://storage.googleapis.com/fao-gismgr-gaez-v5-data/DATA/GAEZ-V5/MAPSET';

  Uri buildRasterUrl({
    required String mapset,
    required String period,
    required String climate,
    required String scenario,
    required String crop,
    required String input,
  }) {
    final fileName =
        'GAEZ-V5.$mapset.$period.$climate.$scenario.$crop.$input.tif';
    return Uri.parse(
      '$officialRasterBaseUrl/$mapset/$fileName',
    );
  }

  Map<String, dynamic> historicalCropDataset({
    required String crop,
    String input = 'HRLM',
  }) {
    return {
      'source': 'FAO/IIASA GAEZ v5',
      'resource': 'RES05',
      'period': 'HP0120',
      'climate': 'AGERA5',
      'scenario': 'HIST',
      'crop': crop,
      'input': input,
      'mapset': 'RES05-ETL',
    };
  }

  Uri buildOfficialQueryUrl({
    String? crop,
    String? waterSupply,
    String? inputLevel,
  }) {
    final where = <String>[];
    if (crop != null && crop.trim().isNotEmpty) {
      where.add("crop='${crop.trim()}'");
    }
    if (waterSupply != null && waterSupply.trim().isNotEmpty) {
      where.add("water_supply='${waterSupply.trim()}'");
    }
    if (inputLevel != null && inputLevel.trim().isNotEmpty) {
      where.add("input_level='${inputLevel.trim()}'");
    }
    return Uri.parse(officialRes05Url).replace(queryParameters: {
      'f': 'json',
      'where': where.isEmpty ? '1=1' : where.join(' AND '),
      'outFields':
          'name,variable,year,model,rcp,crop,water_supply,input_level,units,download_url,file_id',
      'returnGeometry': 'false',
    });
  }

  Future<Map<String, dynamic>> queryOfficialCatalog({
    String? crop,
    String? waterSupply,
    String? inputLevel,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    try {
      final response = await c.get(
        buildOfficialQueryUrl(
          crop: crop,
          waterSupply: waterSupply,
          inputLevel: inputLevel,
        ),
      );
      if (response.statusCode != 200) {
        throw http.ClientException(
          'GAEZ RES05 query failed: ${response.statusCode}',
        );
      }
      return decodeJsonMap(response.body);
    } finally {
      if (client == null) c.close();
    }
  }

  static Map<String, dynamic> decodeJsonMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object.');
    }
    return decoded;
  }
}
