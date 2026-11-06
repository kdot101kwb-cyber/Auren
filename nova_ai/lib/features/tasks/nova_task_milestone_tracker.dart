class NovaTaskMilestone {
  const NovaTaskMilestone({
    required this.taskId,
    required this.status,
    required this.message,
    required this.isSuccess,
  });

  final String taskId;
  final String status;
  final String message;
  final bool isSuccess;
}

/// Tracks task status transitions without treating the first server snapshot
/// as a completion event. Missing tasks are retained so a paginated response
/// cannot erase their last known status.
class NovaTaskMilestoneTracker {
  static const milestoneStatuses = <String>{
    'succeeded',
    'completed',
    'failed',
    'blocked',
    'awaiting_approval',
  };

  final Map<String, String> _knownStatuses = <String, String>{};
  bool _hasInitialSnapshot = false;

  List<NovaTaskMilestone> update(Iterable<Map<String, dynamic>> tasks) {
    final milestones = <NovaTaskMilestone>[];

    for (final task in tasks) {
      final id = '${task['taskId'] ?? ''}'.trim();
      if (id.isEmpty) continue;

      final status = '${task['status'] ?? 'unknown'}'.trim().toLowerCase();
      final previous = _knownStatuses[id];
      _knownStatuses[id] = status;

      if (!_hasInitialSnapshot || previous == null || previous == status ||
          !milestoneStatuses.contains(status)) {
        continue;
      }

      final title = '${task['type'] ?? 'المهمة'}';
      switch (status) {
        case 'succeeded':
        case 'completed':
          milestones.add(NovaTaskMilestone(
            taskId: id,
            status: status,
            message: 'اكتملت $title بنجاح. NOVA تتابع بقية قائمة المهام.',
            isSuccess: true,
          ));
          break;
        case 'failed':
          milestones.add(NovaTaskMilestone(
            taskId: id,
            status: status,
            message: 'تعطلت $title. راجع تفاصيل الخطأ؛ لا تعتبر المهمة مكتملة.',
            isSuccess: false,
          ));
          break;
        case 'blocked':
          milestones.add(NovaTaskMilestone(
            taskId: id,
            status: status,
            message: 'توقفت $title بسبب عائق يحتاج معالجة.',
            isSuccess: false,
          ));
          break;
        case 'awaiting_approval':
          milestones.add(NovaTaskMilestone(
            taskId: id,
            status: status,
            message: 'تحتاج $title إلى موافقتك قبل أي إجراء حساس.',
            isSuccess: false,
          ));
          break;
      }
    }

    _hasInitialSnapshot = true;
    return List.unmodifiable(milestones);
  }
}
