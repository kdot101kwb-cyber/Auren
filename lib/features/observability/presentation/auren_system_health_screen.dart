import 'package:flutter/material.dart';

import '../../../core/observability/auren_health_snapshot.dart';

/// Read-only presentation for a health snapshot produced by trusted callers.
///
/// This widget deliberately performs no network requests and cannot trigger
/// checks. It only displays a snapshot supplied by the caller.
class AurenSystemHealthScreen extends StatelessWidget {
  const AurenSystemHealthScreen({
    required this.snapshot,
    super.key,
  });

  final AurenHealthSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final status = snapshot.overallStatus;
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN System Health')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_iconFor(status), color: _colorFor(status), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _labelFor(status),
                          key: const Key('overall-health-status'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Checks: ${snapshot.totalChecks}'),
                  const SizedBox(height: 4),
                  Text('Healthy: ${snapshot.count(AurenHealthStatus.healthy)}'),
                  Text('Degraded: ${snapshot.count(AurenHealthStatus.degraded)}'),
                  Text('Unavailable: ${snapshot.count(AurenHealthStatus.unavailable)}'),
                  Text('Unknown: ${snapshot.count(AurenHealthStatus.unknown)}'),
                  const SizedBox(height: 8),
                  Text(
                    'Snapshot: ${_formatTimestamp(snapshot.generatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'هذه لقطة تشخيصية وليست ضماناً لاستمرارية الخدمة. '
                    'تُعرض فقط الفحوص التي أرسلها مصدر موثوق.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (snapshot.checks.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'لا توجد نتائج فحص بعد. لم يتم التحقق من حالة أي خدمة.',
                  key: Key('health-empty-state'),
                ),
              ),
            )
          else
            ...snapshot.checks.map(
              (check) => Card(
                child: ListTile(
                  leading: Icon(
                    _iconFor(check.status),
                    color: _colorFor(check.status),
                  ),
                  title: Text(check.label),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_labelFor(check.status)),
                      if (check.safeSummary != null &&
                          check.safeSummary!.trim().isNotEmpty)
                        Text(check.safeSummary!),
                      Text('Duration: ${check.durationMs} ms'),
                      Text('Checked: ${_formatTimestamp(check.checkedAt)}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _labelFor(AurenHealthStatus status) => switch (status) {
        AurenHealthStatus.healthy => 'Healthy',
        AurenHealthStatus.degraded => 'Degraded',
        AurenHealthStatus.unavailable => 'Unavailable',
        AurenHealthStatus.unknown => 'Unknown',
      };

  static IconData _iconFor(AurenHealthStatus status) => switch (status) {
        AurenHealthStatus.healthy => Icons.check_circle_outline,
        AurenHealthStatus.degraded => Icons.warning_amber_outlined,
        AurenHealthStatus.unavailable => Icons.error_outline,
        AurenHealthStatus.unknown => Icons.help_outline,
      };

  static Color _colorFor(AurenHealthStatus status) => switch (status) {
        AurenHealthStatus.healthy => Colors.green,
        AurenHealthStatus.degraded => Colors.orange,
        AurenHealthStatus.unavailable => Colors.red,
        AurenHealthStatus.unknown => Colors.blueGrey,
      };

  static String _formatTimestamp(DateTime value) {
    final utc = value.toUtc();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${utc.year}-${two(utc.month)}-${two(utc.day)} '
        '${two(utc.hour)}:${two(utc.minute)} UTC';
  }
}
