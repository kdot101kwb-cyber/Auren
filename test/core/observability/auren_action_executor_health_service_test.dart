import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:auren/core/observability/auren_action_executor_health_service.dart';
import 'package:auren/core/observability/auren_health_snapshot.dart';

void main() {
  final checkedAt = DateTime.utc(2026, 10, 20, 18);

  group('AurenActionExecutorHealthService', () {
    test('returns unknown when endpoint is not configured as HTTPS', () async {
      final service = AurenActionExecutorHealthService(
        endpoint: 'http://example.test/health',
        clock: () => checkedAt,
      );
      addTearDown(service.close);

      final snapshot = await service.check();

      expect(snapshot.overallStatus, AurenHealthStatus.unknown);
      expect(snapshot.checks.single.safeSummary, contains('HTTPS'));
    });

    test('maps successful health response without sending credentials', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        expect(request.url.scheme, 'https');
        expect(request.url.path, '/health');
        expect(request.headers.containsKey('authorization'), isFalse);
        return http.Response(
          jsonEncode({
            'ok': true,
            'service': 'auren-action-executor',
            'aiConfigured': true,
            'pluginWorkerConfigured': false,
            'privateDetails': 'must be ignored',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = AurenActionExecutorHealthService(
        client: client,
        endpoint: 'https://example.test/health',
        clock: () => checkedAt,
      );
      addTearDown(service.close);

      final snapshot = await service.check();

      expect(called, isTrue);
      expect(snapshot.overallStatus, AurenHealthStatus.degraded);
      expect(snapshot.totalChecks, 3);
      expect(snapshot.checks.map((c) => c.safeSummary),
          isNot(contains('must be ignored')));
    });

    test('does not treat non-2xx response as healthy', () async {
      final service = AurenActionExecutorHealthService(
        client: MockClient((_) async => http.Response('private error', 503)),
        endpoint: 'https://example.test/health',
        clock: () => checkedAt,
      );
      addTearDown(service.close);

      final snapshot = await service.check();

      expect(snapshot.overallStatus, AurenHealthStatus.unknown);
      expect(snapshot.checks.single.safeSummary, 'Health endpoint returned HTTP 503');
      expect(snapshot.checks.single.safeSummary, isNot(contains('private error')));
    });

    test('returns unknown for malformed JSON', () async {
      final service = AurenActionExecutorHealthService(
        client: MockClient((_) async => http.Response('{bad json', 200)),
        endpoint: 'https://example.test/health',
        clock: () => checkedAt,
      );
      addTearDown(service.close);

      final snapshot = await service.check();

      expect(snapshot.overallStatus, AurenHealthStatus.unknown);
      expect(snapshot.checks.single.safeSummary, 'Health response was invalid JSON');
    });

    test('rejects oversized response bodies', () async {
      final service = AurenActionExecutorHealthService(
        client: MockClient((_) async => http.Response('x' * (17 * 1024), 200)),
        endpoint: 'https://example.test/health',
        clock: () => checkedAt,
      );
      addTearDown(service.close);

      final snapshot = await service.check();

      expect(snapshot.overallStatus, AurenHealthStatus.unknown);
      expect(snapshot.checks.single.safeSummary,
          'Health response exceeded size limit');
    });
  });
}
