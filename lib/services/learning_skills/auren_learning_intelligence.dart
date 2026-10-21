/// Deterministic, local-first learning plan recommendations. No AI/network call.
class AurenLearningStep {
  const AurenLearningStep({required this.title, required this.kind, required this.minutes, required this.level});
  final String title;
  final String kind;
  final int minutes;
  final String level;
}

class AurenLearningPlan {
  const AurenLearningPlan({required this.goal, required this.level, required this.dailyMinutes, required this.steps});
  final String goal;
  final String level;
  final int dailyMinutes;
  final List<AurenLearningStep> steps;
  int get totalMinutes => steps.fold(0, (sum, step) => sum + step.minutes);
}

class AurenLearningIntelligence {
  const AurenLearningIntelligence();

  AurenLearningPlan buildPlan({
    required String goal,
    required String level,
    required int minutesPerDay,
    Iterable<String> focusAreas = const [],
  }) {
    final cleanGoal = goal.trim();
    final cleanLevel = level.trim().toLowerCase();
    if (cleanGoal.isEmpty || cleanGoal.length > 120) {
      throw ArgumentError.value(goal, 'goal', 'must be 1–120 characters');
    }
    if (!const {'beginner', 'intermediate', 'advanced'}.contains(cleanLevel)) {
      throw ArgumentError.value(level, 'level', 'must be beginner, intermediate, or advanced');
    }
    if (minutesPerDay < 5 || minutesPerDay > 180) {
      throw ArgumentError.value(minutesPerDay, 'minutesPerDay', 'must be 5–180');
    }
    final focus = focusAreas.map((s) => s.trim()).where((s) => s.isNotEmpty).take(5).toList();
    if (focus.any((s) => s.length > 80)) throw ArgumentError('Focus area is too long');
    final mins = minutesPerDay;
    final review = (mins * .15).round().clamp(1, mins);
    final practice = (mins * (cleanLevel == 'beginner' ? .20 : .35)).round().clamp(1, mins);
    final assessment = (mins * .10).round().clamp(1, mins);
    final learn = mins - review - practice - assessment;
    final focusLabel = focus.isEmpty ? cleanGoal : focus.first;
    final steps = <AurenLearningStep>[
      AurenLearningStep(title: 'Review previous learning', kind: 'review', minutes: review, level: cleanLevel),
      AurenLearningStep(title: 'Learn: $focusLabel', kind: 'lesson', minutes: learn > 0 ? learn : 1, level: cleanLevel),
      AurenLearningStep(title: 'Practice: $focusLabel', kind: 'practice', minutes: practice, level: cleanLevel),
      AurenLearningStep(title: 'Check understanding', kind: 'assessment', minutes: assessment, level: cleanLevel),
    ];
    // Keep the plan within the user's daily budget, even at the minimum.
    var excess = steps.fold<int>(0, (sum, step) => sum + step.minutes) - mins;
    for (var i = 1; i >= 0 && excess > 0; i--) {
      final reducible = steps[i].minutes - 1;
      final reduce = reducible.clamp(0, excess);
      if (reduce > 0) {
        final old = steps[i];
        steps[i] = AurenLearningStep(title: old.title, kind: old.kind, minutes: old.minutes - reduce, level: old.level);
        excess -= reduce;
      }
    }
    return AurenLearningPlan(goal: cleanGoal, level: cleanLevel, dailyMinutes: mins, steps: List.unmodifiable(steps));
  }
}
