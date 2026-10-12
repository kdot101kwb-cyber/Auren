/// Deterministic planning helpers for AUREN's Goal-to-Reality experience.
///
/// Generates a lightweight plan only; it does not schedule external events,
/// spend money, or execute actions on behalf of the user.
class GoalMilestone {
  const GoalMilestone({
    required this.id,
    required this.title,
    required this.estimatedMinutes,
    this.dependsOn = const <String>{},
  });

  final String id;
  final String title;
  final int estimatedMinutes;
  final Set<String> dependsOn;
}

class PlannedMilestone {
  const PlannedMilestone({
    required this.milestone,
    required this.suggestedDay,
    required this.week,
  });

  final GoalMilestone milestone;
  final int suggestedDay;
  final int week;
}

class GoalPlan {
  const GoalPlan({
    required this.items,
    required this.totalMinutes,
    required this.estimatedWeeks,
  });

  final List<PlannedMilestone> items;
  final int totalMinutes;
  final int estimatedWeeks;
}

class GoalActionPlanner {
  const GoalActionPlanner();

  GoalPlan build({
    required List<GoalMilestone> milestones,
    required int minutesPerDay,
  }) {
    if (minutesPerDay <= 0) {
      throw ArgumentError.value(minutesPerDay, 'minutesPerDay', 'Must be positive');
    }

    final byId = <String, GoalMilestone>{};
    for (final item in milestones) {
      if (item.id.trim().isEmpty) throw ArgumentError('Milestone IDs must not be blank');
      if (byId.containsKey(item.id)) throw ArgumentError('Duplicate milestone ID: ${item.id}');
      if (item.estimatedMinutes <= 0) {
        throw ArgumentError.value(item.estimatedMinutes, 'estimatedMinutes', 'Must be positive');
      }
      byId[item.id] = item;
    }

    for (final item in milestones) {
      for (final dependency in item.dependsOn) {
        if (!byId.containsKey(dependency)) {
          throw ArgumentError('Unknown dependency "$dependency" for "${item.id}"');
        }
        if (dependency == item.id) {
          throw ArgumentError('A milestone cannot depend on itself: ${item.id}');
        }
      }
    }

    final remaining = List<GoalMilestone>.from(milestones);
    final ordered = <GoalMilestone>[];
    final completed = <String>{};
    while (remaining.isNotEmpty) {
      final nextIndex = remaining.indexWhere((item) => completed.containsAll(item.dependsOn));
      if (nextIndex < 0) {
        throw ArgumentError('Milestone dependencies contain a cycle');
      }
      final next = remaining.removeAt(nextIndex);
      ordered.add(next);
      completed.add(next.id);
    }

    var day = 1;
    var usedToday = 0;
    var totalMinutes = 0;
    final planned = <PlannedMilestone>[];
    for (final item in ordered) {
      totalMinutes += item.estimatedMinutes;
      var remainingMinutes = item.estimatedMinutes;
      while (remainingMinutes > 0) {
        if (usedToday == minutesPerDay) {
          day++;
          usedToday = 0;
        }
        final available = minutesPerDay - usedToday;
        final chunk = remainingMinutes < available ? remainingMinutes : available;
        usedToday += chunk;
        remainingMinutes -= chunk;
      }
      final completionDay = day;
      planned.add(PlannedMilestone(
        milestone: item,
        suggestedDay: completionDay,
        week: ((completionDay - 1) ~/ 7) + 1,
      ));
    }

    final weeks = totalMinutes == 0 ? 0 :
        (totalMinutes / (minutesPerDay * 7)).ceil();
    return GoalPlan(
      items: List.unmodifiable(planned),
      totalMinutes: totalMinutes,
      estimatedWeeks: weeks,
    );
  }
}
