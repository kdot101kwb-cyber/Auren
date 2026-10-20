import 'package:flutter/foundation.dart';

/// A household maintenance record, separate from reminders and calendar events.
/// This is a local domain model: it does not contact or hire a provider.
enum AurenMaintenanceStatus { planned, inProgress, completed, cancelled }

@immutable
class AurenMaintenanceTask {
  final String id;
  final String title;
  final String area;
  final String description;
  final DateTime? dueAt;
  final int? estimatedCostMinor;
  final int? actualCostMinor;
  final AurenMaintenanceStatus status;

  const AurenMaintenanceTask({
    required this.id,
    required this.title,
    required this.area,
    this.description = '',
    this.dueAt,
    this.estimatedCostMinor,
    this.actualCostMinor,
    this.status = AurenMaintenanceStatus.planned,
  });

  String? validate() {
    if (id.trim().isEmpty) return 'Task id is required.';
    if (title.trim().isEmpty || title.trim().length > 120) {
      return 'Title must contain 1–120 characters.';
    }
    if (area.trim().isEmpty || area.trim().length > 80) {
      return 'Area must contain 1–80 characters.';
    }
    if (description.length > 2000) return 'Description is too long.';
    if (estimatedCostMinor != null && estimatedCostMinor! < 0) {
      return 'Estimated cost cannot be negative.';
    }
    if (actualCostMinor != null && actualCostMinor! < 0) {
      return 'Actual cost cannot be negative.';
    }
    if (status != AurenMaintenanceStatus.completed && actualCostMinor != null) {
      return 'Actual cost can only be recorded for completed tasks.';
    }
    return null;
  }

  AurenMaintenanceTask copyWith({
    String? id,
    String? title,
    String? area,
    String? description,
    DateTime? dueAt,
    bool clearDueAt = false,
    int? estimatedCostMinor,
    int? actualCostMinor,
    bool clearActualCost = false,
    AurenMaintenanceStatus? status,
  }) => AurenMaintenanceTask(
    id: id ?? this.id,
    title: title ?? this.title,
    area: area ?? this.area,
    description: description ?? this.description,
    dueAt: clearDueAt ? null : dueAt ?? this.dueAt,
    estimatedCostMinor: estimatedCostMinor ?? this.estimatedCostMinor,
    actualCostMinor: clearActualCost ? null : actualCostMinor ?? this.actualCostMinor,
    status: status ?? this.status,
  );
}

class AurenMaintenancePlanner {
  const AurenMaintenancePlanner._();

  static List<AurenMaintenanceTask> activeTasks(
    Iterable<AurenMaintenanceTask> tasks,
  ) => tasks
      .where((task) =>
          task.validate() == null &&
          task.status != AurenMaintenanceStatus.completed &&
          task.status != AurenMaintenanceStatus.cancelled)
      .toList()
    ..sort((a, b) {
      if (a.dueAt == null && b.dueAt == null) {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      if (a.dueAt == null) return 1;
      if (b.dueAt == null) return -1;
      final byDate = a.dueAt!.compareTo(b.dueAt!);
      return byDate != 0
          ? byDate
          : a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

  static int? totalEstimatedCostMinor(Iterable<AurenMaintenanceTask> tasks) {
    var total = 0;
    for (final task in tasks) {
      if (task.validate() != null || task.estimatedCostMinor == null) continue;
      total += task.estimatedCostMinor!;
    }
    return total;
  }
}


/// Prevents accidental reopening or skipping maintenance task states.
class AurenMaintenanceLifecycle {
  const AurenMaintenanceLifecycle._();

  static bool canTransition(
    AurenMaintenanceStatus from,
    AurenMaintenanceStatus to,
  ) {
    if (from == to) return true;
    switch (from) {
      case AurenMaintenanceStatus.planned:
        return to == AurenMaintenanceStatus.inProgress ||
            to == AurenMaintenanceStatus.completed ||
            to == AurenMaintenanceStatus.cancelled;
      case AurenMaintenanceStatus.inProgress:
        return to == AurenMaintenanceStatus.completed ||
            to == AurenMaintenanceStatus.cancelled;
      case AurenMaintenanceStatus.completed:
      case AurenMaintenanceStatus.cancelled:
        return false;
    }
  }

  static AurenMaintenanceTask transition(
    AurenMaintenanceTask task,
    AurenMaintenanceStatus next,
  ) {
    final issue = task.validate();
    if (issue != null) throw ArgumentError(issue);
    if (!canTransition(task.status, next)) {
      throw StateError('Invalid maintenance status transition: ${task.status.name} -> ${next.name}.');
    }
    return task.copyWith(status: next);
  }
}
