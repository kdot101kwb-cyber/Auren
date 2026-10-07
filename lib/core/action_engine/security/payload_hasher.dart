import 'dart:convert';
import 'package:crypto/crypto.dart';

class PayloadHasher {
  static String computeHash(Map<String, dynamic> payload) {
    final canonical = _canonicalize(payload);
    return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
  }

  static dynamic _canonicalize(dynamic value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return <String, dynamic>{
        for (final key in keys) key: _canonicalize(value[key]),
      };
    }
    if (value is List) {
      return value.map(_canonicalize).toList();
    }
    return value;
  }
}