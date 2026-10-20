import 'package:flutter_test/flutter_test.dart';
import 'package:auren/core/observability/auren_health_snapshot.dart';

AurenHealthCheck check(
  String id,
  AurenHealthStatus status, {
  int durationMs = 12,
}) =>
    AurenHealthCheck(
      id: id,
      label: 'Check $id',
      status: status,
      checkedAt: DateTime.utc(2026, 10, 20),
      durationMs: durationMs,
      safeSummary: 'Safe status summary',
    );

void main() {
  group('AurenHealthSnapshot', () {
    test('empty snapshots are unknown rather than falsely healthy', () {
      final snapshot = AurenHealthSnapshot(
        generatedAt: DateTime.utc(2026, 10, 20),
        checks: const [],
      );

      expect(snapshot.overallStatus, AurenHealthStatus.unknown);
      expect(snapshot.totalChecks, 0);
    });

    test('all healthy checks produce a healthy snapshot and counts', () {
      final snapshot = AurenHealthSnapshot(
        generatedAt: DateTime.utc(2026, 10, 20),
        checks: [
          check('auth', AurenHealthStatus.healthy),
          check('database', AurenHealthStatus.healthy, durationMs: 0),
        ],
      );

      expect(snapshot.overallStatus, AurenHealthStatus.healthy);
      expect(snapshot.totalChecks, 2);
      expect(snapshot.count(AurenHealthStatus.healthy), 2);
      expect(snapshot.count(AurenHealthStatus.unavailable), 0);
    });

    test('unavailable takes precedence over degraded and unknown', () {
      final snapshot = AurenHealthSnapshot(
        generatedAt: DateTime.utc(2026, 10, 20),
        checks: [
          check('cache', AurenHealthStatus.degraded),
          check('queue', AurenHealthStatus.unknown),
          check('database', AurenHealthStatus.unavailable),
        ],
      );

      expect(snapshot.overallStatus, AurenHealthStatus.unavailable);
    });

    test('degraded takes precedence over unknown when none are unavailable', () {
      final snapshot = AurenHealthSnapshot(
        generatedAt: DateTime.utc(2026, 10, 20),
        checks: [
          check('cache', AurenHealthStatus.degraded),
          check('worker', AurenHealthStatus.unknown),
        ],
      );

      expect(snapshot.overallStatus, AurenHealthStatus.degraded);
    });

    test('rejects blank identifiers and negative durations', () {
      expect(
        () => check('  ', AurenHealthStatus.healthy),
        throwsArgumentError,
      );
      expect(
        () => check('network', AurenHealthStatus.healthy, durationMs: -1),
        throwsArgumentError,
      );
    });

    test('rejects duplicate check identifiers', () {
      expect(
        () => AurenHealthSnapshot(
          generatedAt: DateTime.utc(2026, 10, 20),
          checks: [
            check('database', AurenHealthStatus.healthy),
            check('database', AurenHealthStatus.unavailable),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('exposes an immutable check list', () {
      final snapshot = AurenHealthSnapshot(
        generatedAt: DateTime.utc(2026, 10, 20),
        checks: [check('auth', AurenHealthStatus.healthy)],
      );

      expect(
        () => snapshot.checks.add(check('cache', AurenHealthStatus.healthy)),
        throwsUnsupportedError,
      );
    });
  });
}
