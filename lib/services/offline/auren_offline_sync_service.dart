import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent, bounded queue for small non-sensitive offline actions.
/// Callers register replay handlers; nothing is sent without a handler.
class AurenOfflineSyncService {
  AurenOfflineSyncService._();
  static final AurenOfflineSyncService instance = AurenOfflineSyncService._();

  static const _queueKey = 'auren_offline_sync_queue_v1';

  final Connectivity _connectivity = Connectivity();
  final Map<String, Future<void> Function(Map<String, dynamic>)> _handlers = {};
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _flushing = false;

  Future<void> start() async {
    await _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (_hasConnection(results)) unawaited(flush());
    });
    final current = await _connectivity.checkConnectivity();
    if (_hasConnection(current)) await flush();
  }

  void registerHandler(
    String type,
    Future<void> Function(Map<String, dynamic> payload) handler,
  ) {
    _handlers[type] = handler;
  }

  void unregisterHandler(String type) => _handlers.remove(type);

  Future<String> enqueue({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await _readQueue(prefs);
    final id = '${DateTime.now().microsecondsSinceEpoch}-$type';

    items.add({
      'id': id,
      'type': type,
      'payload': payload,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });

    if (items.length > 100) {
      items.removeRange(0, items.length - 100);
    }
    await prefs.setString(_queueKey, jsonEncode(items));
    return id;
  }

  Future<List<Map<String, dynamic>>> pending() async {
    final prefs = await SharedPreferences.getInstance();
    return _readQueue(prefs);
  }

  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await _readQueue(prefs);
      if (items.isEmpty) return;

      final remaining = <Map<String, dynamic>>[];
      for (final item in items) {
        final type = item['type'];
        final payload = item['payload'];
        if (type is! String || payload is! Map) continue;

        final handler = _handlers[type];
        if (handler == null) {
          remaining.add(item);
          continue;
        }

        try {
          await handler(Map<String, dynamic>.from(payload));
        } catch (_) {
          remaining.add(item);
        }
      }
      await prefs.setString(_queueKey, jsonEncode(remaining));
    } finally {
      _flushing = false;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  Future<List<Map<String, dynamic>>> _readQueue(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
