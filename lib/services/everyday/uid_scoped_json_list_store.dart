import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

typedef AurenJsonRecordDecoder<T> = T Function(Map<String, dynamic> json);
typedef AurenJsonRecordEncoder<T> = Map<String, dynamic> Function(T record);
typedef AurenRecordValidator<T> = String? Function(T record);

/// Small device-local JSON list storage shared by Everyday services.
///
/// Each list is namespaced by an opaque caller-supplied UID. The caller must
/// obtain that UID from the authenticated session; this helper does not
/// authenticate users, encrypt values, or provide cross-device synchronization.
class AurenUidScopedJsonListStore<T> {
  AurenUidScopedJsonListStore({
    required String keyPrefix,
    SharedPreferences? preferences,
  })  : _keyPrefix = keyPrefix,
        _providedPreferences = preferences {
    if (keyPrefix.trim().isEmpty) {
      throw ArgumentError.value(keyPrefix, 'keyPrefix', 'A storage prefix is required.');
    }
  }

  final String _keyPrefix;
  final SharedPreferences? _providedPreferences;

  Future<SharedPreferences> get _preferences async =>
      _providedPreferences ?? SharedPreferences.getInstance();

  String _keyFor(String uid) {
    final normalized = uid.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'Authenticated user id is required.');
    }
    return '$_keyPrefix${base64Url.encode(utf8.encode(normalized))}';
  }

  Future<List<T>> load(
    String uid, {
    required AurenJsonRecordDecoder<T> decode,
    required AurenRecordValidator<T> validate,
  }) async {
    final key = _keyFor(uid);
    final raw = (await _preferences).getString(key);
    if (raw == null || raw.isEmpty) return List<T>.unmodifiable(<T>[]);

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] is! int ||
        decoded['version'] != 1 ||
        decoded['items'] is! List) {
      throw const FormatException('Stored Everyday records have an invalid shape.');
    }

    final records = <T>[];
    for (final entry in decoded['items'] as List) {
      if (entry is! Map) {
        throw const FormatException('A stored Everyday record is invalid.');
      }
      final record = decode(Map<String, dynamic>.from(entry));
      final issue = validate(record);
      if (issue != null) {
        throw FormatException('A stored Everyday record failed validation: $issue');
      }
      records.add(record);
    }
    return List<T>.unmodifiable(records);
  }

  Future<void> saveAll(
    String uid,
    Iterable<T> records, {
    required AurenJsonRecordEncoder<T> encode,
    required AurenRecordValidator<T> validate,
  }) async {
    final key = _keyFor(uid);
    final values = records.toList(growable: false);
    for (final record in values) {
      final issue = validate(record);
      if (issue != null) throw ArgumentError(issue);
    }
    final document = <String, dynamic>{
      'version': 1,
      'items': values.map(encode).toList(growable: false),
    };
    final saved = await (await _preferences).setString(key, jsonEncode(document));
    if (!saved) {
      throw StateError('Could not save Everyday records on this device.');
    }
  }
}
