import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auren_health_endpoint_adapter.dart';
import 'auren_health_snapshot.dart';

/// Fetches the existing public health endpoint with bounded time and payload.
///
/// The health endpoint reports service/configuration metadata only. No
/// Firebase ID token or other credential is sent to it.
class AurenActionExecutorHealthService {
  AurenActionExecutorHealthService({
    http.Client? client,
    String? endpoint,
    this.timeout = const Duration(seconds: 5),
    DateTime Function()? clock,
  })  : _client = client ?? http.Client(),
        _endpoint = endpoint ?? const String.fromEnvironment(
          'AUREN_ACTION_EXECUTOR_HEALTH_URL',
        ),
        _clock = clock ?? DateTime.now;

  static const int _maxResponseBytes = 16 * 1024;

  final http.Client _client;
  final String _endpoint;
  final Duration timeout;
  final DateTime Function() _clock;

  Future<AurenHealthSnapshot> check() async {
    final startedAt = _clock();
    final uri = Uri.tryParse(_endpoint.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return _unknown(startedAt, 0, 'Health endpoint is not configured with HTTPS');
    }

    try {
      final response = await _client
          .get(uri, headers: const {'accept': 'application/json'})
          .timeout(timeout);
      final finishedAt = _clock();
      final durationMs = finishedAt.difference(startedAt).inMilliseconds.clamp(0, 1 << 31).toInt();
      if (response.bodyBytes.length > _maxResponseBytes) {
        return _unknown(finishedAt, durationMs, 'Health response exceeded size limit');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _unknown(finishedAt, durationMs, 'Health endpoint returned HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        return _unknown(finishedAt, durationMs, 'Health response was not an object');
      }
      final safeResponse = <String, Object?>{};
      for (final key in const [
        'ok',
        'service',
        'aiConfigured',
        'pluginWorkerConfigured',
      ]) {
        final value = decoded[key];
        if (value is bool || value is String) safeResponse[key] = value;
      }
      return actionExecutorSnapshotFromResponse(
        response: safeResponse,
        checkedAt: finishedAt,
        durationMs: durationMs,
      );
    } on FormatException {
      return _unknown(_clock(), _elapsedMs(startedAt), 'Health response was invalid JSON');
    } on Exception {
      return _unknown(_clock(), _elapsedMs(startedAt), 'Health endpoint request failed');
    }
  }

  int _elapsedMs(DateTime startedAt) =>
      _clock().difference(startedAt).inMilliseconds.clamp(0, 1 << 31);

  AurenHealthSnapshot _unknown(
    DateTime checkedAt,
    int durationMs,
    String summary,
  ) =>
      AurenHealthSnapshot(
        generatedAt: checkedAt,
        checks: [
          AurenHealthCheck(
            id: 'action_executor.probe',
            label: 'Action executor probe',
            status: AurenHealthStatus.unknown,
            checkedAt: checkedAt,
            durationMs: durationMs,
            safeSummary: summary,
          ),
        ],
      );

  void close() => _client.close();
}
