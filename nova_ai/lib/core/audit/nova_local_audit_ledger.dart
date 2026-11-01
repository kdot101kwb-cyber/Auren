import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NovaAuditEvent {
  const NovaAuditEvent({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.actionId,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String type;
  final String message;
  final DateTime createdAt;
  final String? actionId;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type,
        'message': message,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'actionId': actionId,
        'metadata': metadata,
      };

  static NovaAuditEvent? fromJson(Object? value) {
    if (value is! Map) return null;
    try {
      final map = Map<String, Object?>.from(value);
      final id = map['id'];
      final type = map['type'];
      final message = map['message'];
      final date = DateTime.tryParse('${map['createdAt'] ?? ''}');
      if (id is! String || id.isEmpty || type is! String ||
          type.isEmpty || message is! String || date == null) return null;
      final rawMetadata = map['metadata'];
      return NovaAuditEvent(
        id: id,
        type: type,
        message: message,
        createdAt: date.toUtc(),
        actionId: map['actionId'] is String ? map['actionId']! as String : null,
        metadata: rawMetadata is Map
            ? Map<String, Object?>.from(rawMetadata)
            : const <String, Object?>{},
      );
    } catch (_) {
      return null;
    }
  }
}

/// Bounded, device-local audit history with conservative metadata redaction.
class NovaLocalAuditLedger {
  NovaLocalAuditLedger({
    SharedPreferences? preferences,
    this.storageKey = 'nova.audit.events.v1',
    this.maxEvents = 1000,
  }) : _providedPreferences = preferences;

  final SharedPreferences? _providedPreferences;
  final String storageKey;
  final int maxEvents;

  static const _sensitiveKeyParts = <String>[
    'password', 'passwd', 'token', 'secret', 'seed', 'privatekey',
    'private_key', 'authorization', 'api_key', 'apikey', 'wallet',
    'credential', 'cookie',
  ];

  Future<SharedPreferences> get _prefs async =>
      _providedPreferences ?? SharedPreferences.getInstance();

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll('-', '_');
    return _sensitiveKeyParts.any(normalized.contains);
  }

  static Object? _sanitize(Object? value, {int depth = 0}) {
    if (depth > 5) return '[depth-limited]';
    if (value is Map) {
      final safe = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key.toString();
        safe[key] = _isSensitiveKey(key)
            ? '[redacted]'
            : _sanitize(entry.value, depth: depth + 1);
      }
      return safe;
    }
    if (value is List) {
      return value.take(50)
          .map((item) => _sanitize(item, depth: depth + 1)).toList();
    }
    if (value == null || value is String || value is num || value is bool) {
      if (value is String && value.length > 500) return value.substring(0, 500);
      return value;
    }
    return value.toString().substring(
      0,
      value.toString().length > 200 ? 200 : value.toString().length,
    );
  }

  Future<List<NovaAuditEvent>> read() async {
    final raw = (await _prefs).getString(storageKey);
    if (raw == null) return <NovaAuditEvent>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <NovaAuditEvent>[];
      return decoded.map(NovaAuditEvent.fromJson)
          .whereType<NovaAuditEvent>().take(maxEvents).toList();
    } catch (_) {
      return <NovaAuditEvent>[];
    }
  }

  Future<bool> append({
    required String id,
    required String type,
    required String message,
    String? actionId,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    if (id.trim().isEmpty || type.trim().isEmpty || message.trim().isEmpty) {
      return false;
    }
    final events = await read();
    if (events.any((event) => event.id == id)) return false;
    final safeMetadata = _sanitize(metadata);
    final event = NovaAuditEvent(
      id: id,
      type: type,
      message: message.length > 500 ? message.substring(0, 500) : message,
      createdAt: DateTime.now().toUtc(),
      actionId: actionId,
      metadata: safeMetadata is Map
          ? Map<String, Object?>.from(safeMetadata)
          : const <String, Object?>{},
    );
    events.insert(0, event);
    return (await _prefs).setString(
      storageKey,
      jsonEncode(events.take(maxEvents).map((item) => item.toJson()).toList()),
    );
  }
}
