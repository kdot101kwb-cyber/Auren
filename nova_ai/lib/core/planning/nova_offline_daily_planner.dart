enum NovaPlanPriority { urgent, high, normal, low }

class NovaPlanItem {
  const NovaPlanItem({
    required this.id,
    required this.title,
    required this.estimatedMinutes,
    this.priority = NovaPlanPriority.normal,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final int estimatedMinutes;
  final NovaPlanPriority priority;
  final bool isCompleted;
}

class NovaDailyPlan {
  const NovaDailyPlan({
    required this.scheduled,
    required this.deferred,
    required this.availableMinutes,
    required this.usedMinutes,
  });

  final List<NovaPlanItem> scheduled;
  final List<NovaPlanItem> deferred;
  final int availableMinutes;
  final int usedMinutes;

  int get remainingMinutes => availableMinutes - usedMinutes;
  int get scheduledCount => scheduled.length;
  int get deferredCount => deferred.length;
}

/// Deterministic, offline time-budget planner. It never starts or executes work.
class NovaOfflineDailyPlanner {
  const NovaOfflineDailyPlanner();

  NovaDailyPlan build({
    required List<NovaPlanItem> items,
    required int availableMinutes,
  }) {
    if (availableMinutes < 0) {
      throw ArgumentError.value(availableMinutes, 'availableMinutes');
    }

    final seen = <String>{};
    final pending = items.where((item) {
      if (item.isCompleted ||
          item.id.trim().isEmpty ||
          item.title.trim().isEmpty ||
          item.estimatedMinutes <= 0 ||
          !seen.add(item.id)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final priority = a.priority.index.compareTo(b.priority.index);
        if (priority != 0) return priority;
        final duration = a.estimatedMinutes.compareTo(b.estimatedMinutes);
        if (duration != 0) return duration;
        return a.id.compareTo(b.id);
      });

    final scheduled = <NovaPlanItem>[];
    final deferred = <NovaPlanItem>[];
    var remaining = availableMinutes;
    for (final item in pending) {
      if (item.estimatedMinutes <= remaining) {
        scheduled.add(item);
        remaining -= item.estimatedMinutes;
      } else {
        deferred.add(item);
      }
    }

    return NovaDailyPlan(
      scheduled: List.unmodifiable(scheduled),
      deferred: List.unmodifiable(deferred),
      availableMinutes: availableMinutes,
      usedMinutes: availableMinutes - remaining,
    );
  }
}
