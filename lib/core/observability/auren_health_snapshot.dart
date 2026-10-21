/// Small, dependency-free health primitives for AUREN subsystem diagnostics.
///
/// This model intentionally does not probe Firebase, network endpoints, or
/// third-party providers itself. Callers must perform authorized checks and
/// pass only safe, non-sensitive summaries into the snapshot.
enum AurenHealthStatus { healthy, degraded, unavailable, unknown }

class AurenHealthCheck {
  AurenHealthCheck({
    required this.id,
    required this.label,
    required this.status,
    required this.checkedAt,
    required this.durationMs,
    this.safeSummary,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be empty');
    }
    if (durationMs < 0) {
      throw ArgumentError.value(durationMs, 'durationMs', 'must be >= 0');
    }
  }

  final String id;
  final String label;
  final AurenHealthStatus status;
  final DateTime checkedAt;
  final int durationMs;

  /// A short, pre-sanitized message. Never pass tokens, credentials, raw
  /// request headers, user content, or unfiltered exception strings here.
  final String? safeSummary;
}

class AurenHealthSnapshot {
  AurenHealthSnapshot({
    required this.generatedAt,
    required List<AurenHealthCheck> checks,
  }) : checks = List<AurenHealthCheck>.unmodifiable(checks) {
    final ids = <String>{};
    for (final check in this.checks) {
      if (!ids.add(check.id)) {
        throw ArgumentError.value(check.id, 'checks', 'check IDs must be unique');
      }
    }
  }

  final DateTime generatedAt;
  final List<AurenHealthCheck> checks;

  AurenHealthStatus get overallStatus {
    if (checks.isEmpty) return AurenHealthStatus.unknown;
    if (checks.any((check) => check.status == AurenHealthStatus.unavailable)) {
      return AurenHealthStatus.unavailable;
    }
    if (checks.any((check) => check.status == AurenHealthStatus.degraded)) {
      return AurenHealthStatus.degraded;
    }
    if (checks.any((check) => check.status == AurenHealthStatus.unknown)) {
      return AurenHealthStatus.unknown;
    }
    return AurenHealthStatus.healthy;
  }

  int count(AurenHealthStatus status) =>
      checks.where((check) => check.status == status).length;

  int get totalChecks => checks.length;
}
