import 'auren_health_snapshot.dart';

/// Converts the existing action-executor `/health` JSON into a safe snapshot.
///
/// This adapter does not perform network requests. Callers must fetch the
/// endpoint through an approved transport and pass the decoded response here.
/// A configured worker or AI provider is not proof that the dependency is live.
AurenHealthSnapshot actionExecutorSnapshotFromResponse({
  required Map<String, Object?> response,
  required DateTime checkedAt,
  required int durationMs,
}) {
  final service = response['service'];
  final ok = response['ok'];
  final isExpectedService = service == 'auren-action-executor';

  if (!isExpectedService || ok is! bool) {
    return AurenHealthSnapshot(
      generatedAt: checkedAt,
      checks: [
        AurenHealthCheck(
          id: 'action_executor.response',
          label: 'Action executor response',
          status: AurenHealthStatus.unknown,
          checkedAt: checkedAt,
          durationMs: durationMs,
          safeSummary: 'Unexpected health response format',
        ),
      ],
    );
  }

  final endpointStatus =
      ok ? AurenHealthStatus.healthy : AurenHealthStatus.unavailable;
  final aiConfigured = response['aiConfigured'] == true;
  final workerConfigured = response['pluginWorkerConfigured'] == true;

  return AurenHealthSnapshot(
    generatedAt: checkedAt,
    checks: [
      AurenHealthCheck(
        id: 'action_executor.endpoint',
        label: 'Action executor endpoint',
        status: endpointStatus,
        checkedAt: checkedAt,
        durationMs: durationMs,
        safeSummary: ok ? 'Endpoint responded' : 'Endpoint reports failure',
      ),
      AurenHealthCheck(
        id: 'action_executor.ai_configuration',
        label: 'AI configuration',
        status: aiConfigured
            ? AurenHealthStatus.healthy
            : AurenHealthStatus.degraded,
        checkedAt: checkedAt,
        durationMs: 0,
        safeSummary: aiConfigured
            ? 'Required AI settings are present'
            : 'One or more required AI settings are missing',
      ),
      AurenHealthCheck(
        id: 'action_executor.worker_configuration',
        label: 'Plugin worker configuration',
        status: workerConfigured
            ? AurenHealthStatus.healthy
            : AurenHealthStatus.degraded,
        checkedAt: checkedAt,
        durationMs: 0,
        safeSummary: workerConfigured
            ? 'Worker URL is configured'
            : 'Worker URL is not configured',
      ),
    ],
  );
}
