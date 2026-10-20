import 'package:auren/core/observability/auren_health_snapshot.dart';
import 'package:auren/features/observability/presentation/auren_system_health_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

AurenHealthCheck makeCheck({
  required String id,
  required String label,
  required AurenHealthStatus status,
  String? safeSummary,
}) =>
    AurenHealthCheck(
      id: id,
      label: label,
      status: status,
      checkedAt: DateTime.utc(2026, 10, 20, 12, 30),
      durationMs: 24,
      safeSummary: safeSummary,
    );

Widget host(AurenHealthSnapshot snapshot) => MaterialApp(
      home: AurenSystemHealthScreen(snapshot: snapshot),
    );

void main() {
  group('AurenSystemHealthScreen', () {
    testWidgets('empty snapshot says service health has not been verified',
        (tester) async {
      await tester.pumpWidget(
        host(
          AurenHealthSnapshot(
            generatedAt: DateTime.utc(2026, 10, 20),
            checks: const [],
          ),
        ),
      );

      expect(find.text('Unknown'), findsOneWidget);
      expect(find.byKey(const Key('health-empty-state')), findsOneWidget);
      expect(
        find.text('لا توجد نتائج فحص بعد. لم يتم التحقق من حالة أي خدمة.'),
        findsOneWidget,
      );
    });

    testWidgets('renders check labels, statuses, duration and safe summary',
        (tester) async {
      await tester.pumpWidget(
        host(
          AurenHealthSnapshot(
            generatedAt: DateTime.utc(2026, 10, 20, 12),
            checks: [
              makeCheck(
                id: 'database',
                label: 'Database',
                status: AurenHealthStatus.healthy,
                safeSummary: 'Read-only probe passed',
              ),
              makeCheck(
                id: 'worker',
                label: 'Worker',
                status: AurenHealthStatus.degraded,
              ),
            ],
          ),
        ),
      );

      expect(find.byKey(const Key('overall-health-status')), findsOneWidget);
      expect(find.text('Degraded'), findsOneWidget);
      expect(find.text('Database'), findsOneWidget);
      expect(find.text('Worker'), findsOneWidget);
      expect(find.text('Read-only probe passed'), findsOneWidget);
      expect(find.text('Duration: 24 ms'), findsNWidgets(2));
      expect(find.text('Healthy: 1'), findsOneWidget);
      expect(find.text('Degraded: 1'), findsOneWidget);
      expect(find.text('Snapshot: 2026-10-20 12:00 UTC'), findsOneWidget);
    });

    testWidgets('does not display empty or whitespace-only summaries',
        (tester) async {
      await tester.pumpWidget(
        host(
          AurenHealthSnapshot(
            generatedAt: DateTime.utc(2026, 10, 20),
            checks: [
              makeCheck(
                id: 'queue',
                label: 'Queue',
                status: AurenHealthStatus.unknown,
                safeSummary: '   ',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Queue'), findsOneWidget);
      expect(find.text('   '), findsNothing);
    });
  });
}
