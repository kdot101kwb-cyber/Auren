import 'package:cloud_functions/cloud_functions.dart';

class AgricultureMarketPrice {
  final String id;
  final String market;
  final String commodity;
  final String category;
  final double price;
  final String currency;
  final String unit;
  final String source;
  final String? sourceUrl;
  final String? exchange;
  final String? updatedAt;
  final String country;
  final String state;
  final String city;
  final String marketName;
  final bool live;
  final bool verified;

  const AgricultureMarketPrice({
    required this.id, required this.market, required this.commodity, required this.category,
    required this.price, required this.currency, required this.unit, required this.source,
    required this.sourceUrl, required this.exchange, required this.updatedAt, required this.country,
    required this.state, required this.city, required this.marketName, required this.live, required this.verified,
  });

  factory AgricultureMarketPrice.fromMap(Map<String, dynamic> m) => AgricultureMarketPrice(
    id:'\${m['id'] ?? ''}', market:'\${m['market'] ?? ''}', commodity:'\${m['commodity'] ?? ''}',
    category:'\${m['category'] ?? ''}', price:(m['price'] as num?)?.toDouble() ?? 0,
    currency:'\${m['currency'] ?? ''}', unit:'\${m['unit'] ?? ''}', source:'\${m['source'] ?? ''}',
    sourceUrl:m['sourceUrl']?.toString(), exchange:m['exchange']?.toString(),
    updatedAt:m['updatedAt']?.toString(), country:'\${m['country'] ?? ''}',
    state:'\${m['state'] ?? ''}', city:'\${m['city'] ?? ''}', marketName:'\${m['marketName'] ?? ''}',
    live:m['live'] == true, verified:m['verified'] == true,
  );
}

class AgricultureMarketPricesService {
  final FirebaseFunctions functions;
  AgricultureMarketPricesService({FirebaseFunctions? functions})
      : functions = functions ?? FirebaseFunctions.instanceFor(region:'us-central1');

  Future<Map<String, dynamic>> getPrices({
    String country = 'ALL', String state = '', String city = '', String commodity = '',
  }) async {
    final result = await functions.httpsCallable('aurenAgricultureMarketPrices').call({
      'country':country, 'state':state, 'city':city, 'commodity':commodity, 'limit':50,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final global = (data['global'] as List? ?? const [])
        .whereType<Map>().map((x) => AgricultureMarketPrice.fromMap(Map<String,dynamic>.from(x))).toList();
    final local = (data['local'] as List? ?? const [])
        .whereType<Map>().map((x) => AgricultureMarketPrice.fromMap(Map<String,dynamic>.from(x))).toList();
    return {'global':global, 'local':local, 'localDataNote':data['localDataNote']?.toString()};
  }
}
