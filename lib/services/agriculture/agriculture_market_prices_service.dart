import 'package:cloud_functions/cloud_functions.dart';

class AgricultureMarketPrice {
  final String id;
  final String market;
  final String commodity;
  final String category;
  final String country;
  final String countryCode;
  final String state;
  final String city;
  final String marketName;
  final double? price;
  final String currency;
  final String unit;
  final String source;
  final String sourceUrl;
  final String exchange;
  final bool verified;
  final String? observedAt;

  const AgricultureMarketPrice({
    required this.id,
    required this.market,
    required this.commodity,
    required this.category,
    required this.country,
    required this.countryCode,
    required this.state,
    required this.city,
    required this.marketName,
    required this.price,
    required this.currency,
    required this.unit,
    required this.source,
    required this.sourceUrl,
    required this.exchange,
    required this.verified,
    required this.observedAt,
  });

  factory AgricultureMarketPrice.fromMap(Map<String, dynamic> d) {
    return AgricultureMarketPrice(
      id: (d['id'] ?? '').toString(),
      market: (d['market'] ?? '').toString(),
      commodity: (d['commodity'] ?? '').toString(),
      category: (d['category'] ?? '').toString(),
      country: (d['country'] ?? '').toString(),
      countryCode: (d['countryCode'] ?? '').toString(),
      state: (d['state'] ?? d['region'] ?? '').toString(),
      city: (d['city'] ?? '').toString(),
      marketName: (d['marketName'] ?? d['market'] ?? '').toString(),
      price: (d['price'] as num?)?.toDouble(),
      currency: (d['currency'] ?? '').toString(),
      unit: (d['unit'] ?? '').toString(),
      source: (d['source'] ?? '').toString(),
      sourceUrl: (d['sourceUrl'] ?? '').toString(),
      exchange: (d['exchange'] ?? '').toString(),
      verified: d['verified'] == true,
      observedAt: d['observedAt']?.toString(),
    );
  }
}

class AgricultureMarketPricesService {
  final FirebaseFunctions functions;
  AgricultureMarketPricesService({FirebaseFunctions? functions})
      : functions = functions ?? FirebaseFunctions.instance;

  Future<List<AgricultureMarketPrice>> getGlobalCommodityPrices({
    String commodity = '',
  }) async {
    final result = await functions
        .httpsCallable('aurenAgriGlobalCommodityPrices')
        .call({'commodity': commodity.trim()});
    final data = result.data is Map ? result.data as Map : const {};
    final rows = data['data'] is List ? data['data'] as List : const [];
    return rows
        .whereType<Map>()
        .map((e) => AgricultureMarketPrice.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, List<AgricultureMarketPrice>>> getPrices({
    String country = 'ALL',
    String state = '',
    String city = '',
    String commodity = '',
  }) async {
    final result = await functions
        .httpsCallable('aurenAgricultureMarketPrices')
        .call({
      'country': country.trim().isEmpty ? 'ALL' : country.trim().toUpperCase(),
      'state': state.trim(),
      'city': city.trim(),
      'commodity': commodity.trim(),
    });
    final data = result.data is Map ? result.data as Map : const {};
    List<AgricultureMarketPrice> parse(String key) {
      final rows = data[key] is List ? data[key] as List : const [];
      return rows.whereType<Map>().map((e) {
        return AgricultureMarketPrice.fromMap(Map<String, dynamic>.from(e));
      }).toList();
    }
    return {'global': parse('global'), 'local': parse('local')};
  }
}
