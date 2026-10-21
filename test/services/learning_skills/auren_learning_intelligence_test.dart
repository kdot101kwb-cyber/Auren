import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/learning_skills/auren_learning_intelligence.dart';

void main() {
  const engine = AurenLearningIntelligence();
  test('builds a bounded plan adapted to level, focus and daily time', () {
    final plan = engine.buildPlan(goal: 'Learn Flutter', level: 'beginner', minutesPerDay: 30, focusAreas: ['Widgets']);
    expect(plan.steps.map((step) => step.kind), ['review', 'lesson', 'practice', 'assessment']);
    expect(plan.totalMinutes, lessThanOrEqualTo(30));
    expect(plan.totalMinutes, greaterThan(0));
    expect(plan.steps[1].title, contains('Widgets'));
    expect(plan.steps.every((step) => step.level == 'beginner'), isTrue);
  });
  test('rejects invalid goal, level and budget', () {
    expect(() => engine.buildPlan(goal: ' ', level: 'beginner', minutesPerDay: 30), throwsArgumentError);
    expect(() => engine.buildPlan(goal: 'Goal', level: 'expert-ish', minutesPerDay: 30), throwsArgumentError);
    expect(() => engine.buildPlan(goal: 'Goal', level: 'beginner', minutesPerDay: 181), throwsArgumentError);
  });
}
