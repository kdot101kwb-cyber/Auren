import 'dart:convert';

import 'package:http/http.dart' as http;

/// Read-only monitor for the public TRON chain. It never signs or broadcasts
/// transactions and does not need a wallet seed phrase or private key.
class TronUsdtTransfer {
  const TronUsdtTransfer({
    required this.transactionId,
    required this.from,
    required this.to,
    required this.amount,
    required this.timestamp,
    required this.confirmed,
  });

  final String transactionId;
  final String from;
  final String to;
  final double amount;
  final DateTime? timestamp;
  final bool confirmed;

  factory TronUsdtTransfer.fromMap(Map<String, dynamic> json) {
    final token = json['token_info'];
    final decimals = token is Map && token['decimals'] is num
        ? (token['decimals'] as num).toInt()
        : 6;
    final rawValue = json['value'];
    final value = rawValue is String
        ? (double.tryParse(rawValue) ?? 0)
        : rawValue is num
            ? rawValue.toDouble()
            : 0.0;
    final timestamp = json['block_timestamp'];
    return TronUsdtTransfer(
      transactionId: json['transaction_id']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      amount: value / _pow10(decimals),
      timestamp: timestamp is num
          ? DateTime.fromMillisecondsSinceEpoch(timestamp.toInt(), isUtc: true)
          : null,
      confirmed: json['confirmed'] == true,
    );
  }

  static double _pow10(int n) {
    var result = 1.0;
    for (var i = 0; i < n.clamp(0, 18); i++) {
      result *= 10;
    }
    return result;
  }
}

class TronUsdtMonitor {
  TronUsdtMonitor({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const usdtContract = 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t';
  static const _base = 'https://api.trongrid.io';

  /// Basic local format check only; it is not a full Base58Check validation.
  bool looksLikeTronAddress(String value) =>
      RegExp(r'^T[1-9A-HJ-NP-Za-km-z]{33}$').hasMatch(value.trim());

  Future<double> fetchUsdtBalance(String address) async {
    final normalized = address.trim();
    if (!looksLikeTronAddress(normalized)) {
      throw const FormatException('عنوان TRON غير صالح من حيث الصيغة.');
    }

    final uri = Uri.parse('$_base/v1/accounts/$normalized/tokens').replace(
      queryParameters: {'limit': '200', 'start': '0'},
    );
    final response = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('تعذر جلب الرصيد (HTTP ${response.statusCode}). قد تكون الخدمة محدودة مؤقتاً.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['data'] is! List) {
      throw const FormatException('استجابة الرصيد غير مفهومة.');
    }

    final tokens = decoded['data'] as List;
    for (final item in tokens) {
      if (item is! Map) continue;
      final tokenId = (item['tokenId'] ?? item['token_id'] ?? item['address'] ?? '').toString();
      if (tokenId != usdtContract) continue;
      final decimalsRaw = item['tokenDecimal'] ?? item['token_decimal'] ?? item['decimals'] ?? 6;
      final decimals = decimalsRaw is num ? decimalsRaw.toInt() : int.tryParse('$decimalsRaw') ?? 6;
      final rawBalance = item['balance'] ?? item['quantity'] ?? '0';
      final value = rawBalance is num ? rawBalance.toDouble() : double.tryParse('$rawBalance') ?? 0;
      var divisor = 1.0;
      for (var i = 0; i < decimals.clamp(0, 18); i++) {
        divisor *= 10;
      }
      return value / divisor;
    }
    return 0;
  }

  Future<List<TronUsdtTransfer>> fetchTransfers(String address) async {
    final normalized = address.trim();
    if (!looksLikeTronAddress(normalized)) {
      throw const FormatException('عنوان TRON غير صالح من حيث الصيغة.');
    }

    final uri = Uri.parse('$_base/v1/accounts/$normalized/transactions/trc20').replace(
      queryParameters: {
        'contract_address': usdtContract,
        'only_confirmed': 'true',
        'limit': '30',
        'order_by': 'block_timestamp,desc',
      },
    );
    final response = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('تعذر جلب المعاملات (HTTP ${response.statusCode}). قد تكون الخدمة محدودة مؤقتاً.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['data'] is! List) {
      throw const FormatException('استجابة المعاملات غير مفهومة.');
    }
    return (decoded['data'] as List)
        .whereType<Map>()
        .map((item) => TronUsdtTransfer.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  void close() => _client.close();
}
