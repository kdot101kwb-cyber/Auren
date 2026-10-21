import 'package:flutter_test/flutter_test.dart';
import 'package:auren/core/observability/auren_health_endpoint_adapter.dart';
import 'package:auren/core/observability/auren_health_snapshot.dart';

void main() {
  final checkedAt = DateTime.utc(2026, 10, 20, 17);

  group('actionExecutorSnapshotFromResponse', () {
    test('maps configured response without claiming live dependency health', () {
      final snapshot = actionExecutorSnapshotFromResponse(
        response: const {
          'ok': true,
          'service': 'auren-action-executor',
          'aiConfigured': true,
          'pluginWorkerConfigured': true,
        },
        checkedAt: checkedAt,
        durationMs: 18,
      );

      expect(snapshot.overallStatus, AurenHealthStatus.healthy);
      expect(snapshot.totalChecks, 3);
      expect(snapshot.checks[0].durationMs, 18);
      expect(snapshot.checks[2].safeSummary, 'Worker URL is configured');
    });

    test('reports missing optional service configuration as degraded', () {
      final snapshot = actionExecutorSnapshotFromResponse(
        response: const {
          'ok': true,
          'service': 'auren-action-executor',
          'aiConfigured': false,
          'pluginWorkerConfigured': false,
        },
        checkedAt: checkedAt,
        durationMs: 4,
      );

      expect(snapshot.overallStatus, AurenHealthStatus.degraded);
      expect(snapshot.count(AurenHealthStatus.degraded), 2);
    });

    test('unavailable endpoint takes precedence over configuration flags', () {
      final snapshot = actionExecutorSnapshotFromResponse(
        response: const {
          'ok': false,
          'service': 'auren-action-executor',
          'aiConfigured': true,
          'pluginWorkerConfigured': true,
        },
        checkedAt: checkedAt,
        durationMs: 100,
      );

      expect(snapshot.overallStatus, AurenHealthStatus.unavailable);
    });

    test('unknown response format fails closed without exposing payload', () {
      final snapshot = actionExecutorSnapshotFromResponse(
        response: const {
          'ok': true,
          'service': 'unexpected-service',
          'token': 'must-not-be-copied-to-summary',
        },
        checkedAt: checkedAt,
        durationMs: 3,
      );

      expect(snapshot.overallStatus, AurenHealthStatus.unknown);
      expect(snapshot.checks.single.safeSummary,
          'Unexpected health response format');
      expect(snapshot.checks.single.safeSummary, isNot(contains('token')));
    });
  });
}
