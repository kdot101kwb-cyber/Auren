/// Normalizes GitHub Actions status without treating queued or unknown runs as green.
enum NovaCiRunState { queued, running, succeeded, failed, cancelled, skipped, unknown }

class NovaCiRunStatus {
  const NovaCiRunStatus._(this.state);

  final NovaCiRunState state;

  bool get isVerifiedSuccess => state == NovaCiRunState.succeeded;
  bool get needsAttention => state == NovaCiRunState.failed ||
      state == NovaCiRunState.cancelled ||
      state == NovaCiRunState.unknown;

  String get label {
    switch (state) {
      case NovaCiRunState.queued:
        return 'في الانتظار';
      case NovaCiRunState.running:
        return 'قيد التنفيذ';
      case NovaCiRunState.succeeded:
        return 'نجاح مثبت';
      case NovaCiRunState.failed:
        return 'فشل';
      case NovaCiRunState.cancelled:
        return 'أُلغي';
      case NovaCiRunState.skipped:
        return 'تم التخطي';
      case NovaCiRunState.unknown:
        return 'حالة غير معروفة';
    }
  }

  static NovaCiRunStatus fromGitHub({
    required String status,
    required String conclusion,
  }) {
    final normalizedStatus = status.trim().toLowerCase();
    final normalizedConclusion = conclusion.trim().toLowerCase();

    if (normalizedStatus != 'completed') {
      if (normalizedStatus == 'queued' || normalizedStatus == 'requested' ||
          normalizedStatus == 'waiting' || normalizedStatus == 'pending') {
        return const NovaCiRunStatus._(NovaCiRunState.queued);
      }
      if (normalizedStatus == 'in_progress') {
        return const NovaCiRunStatus._(NovaCiRunState.running);
      }
      return const NovaCiRunStatus._(NovaCiRunState.unknown);
    }

    switch (normalizedConclusion) {
      case 'success':
        return const NovaCiRunStatus._(NovaCiRunState.succeeded);
      case 'failure':
      case 'timed_out':
      case 'action_required':
        return const NovaCiRunStatus._(NovaCiRunState.failed);
      case 'cancelled':
        return const NovaCiRunStatus._(NovaCiRunState.cancelled);
      case 'skipped':
        return const NovaCiRunStatus._(NovaCiRunState.skipped);
      default:
        return const NovaCiRunStatus._(NovaCiRunState.unknown);
    }
  }
}
