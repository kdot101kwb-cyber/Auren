import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/goals/domain/goal_action_planner.dart';

void main() {
  const planner = GoalActionPlanner();

  test('orders dependencies before dependent milestones', () {
    final plan = planner.build(
      minutesPerDay: 60,
      milestones: const [
        GoalMilestone(id: 'publish', title: 'Publish', estimatedMinutes: 30, dependsOn: {'draft'}),
        GoalMilestone(id: 'draft', title: 'Draft', estimatedMinutes: 90),
      ],
    );
    expect(plan.items.map((item) => item.milestone.id), ['draft', 'publish']);
    expect(plan.totalMinutes, 120);
    expect(plan.estimatedWeeks, 1);
  });

  test('rejects unknown dependencies and dependency cycles', () {
    expect(
      () => planner.build(minutesPerDay: 30, milestones: const [
        GoalMilestone(id: 'a', title: 'A', estimatedMinutes: 10, dependsOn: {'missing'}),
      ]),
      throwsArgumentError,
    );
    expect(
      () => planner.build(minutesPerDay: 30, milestones: const [
        GoalMilestone(id: 'a', title: 'A', estimatedMinutes: 10, dependsOn: {'b'}),
        GoalMilestone(id: 'b', title: 'B', estimatedMinutes: 10, dependsOn: {'a'}),
      ]),
      throwsArgumentError,
    );
  });

  test('rejects invalid durations, duplicate IDs, and nonpositive daily capacity', () {
    expect(
      () => planner.build(minutesPerDay: 0, milestones: const []),
      throwsArgumentError,
    );
    expect(
      () => planner.build(minutesPerDay: 30, milestones: const [
        GoalMilestone(id: 'x', title: 'X', estimatedMinutes: 0),
      ]),
      throwsArgumentError,
    );
    expect(
      () => planner.build(minutesPerDay: 30, milestones: const [
        GoalMilestone(id: 'x', title: 'X', estimatedMinutes: 10),
        GoalMilestone(id: 'x', title: 'Duplicate', estimatedMinutes: 10),
      ]),
      throwsArgumentError,
    );
  });

  test('spreads work over days based on daily capacity', () {
    final plan = planner.build(
      minutesPerDay: 30,
      milestones: const [
        GoalMilestone(id: 'one', title: 'One', estimatedMinutes: 30),
        GoalMilestone(id: 'two', title: 'Two', estimatedMinutes: 45),
      ],
    );
    expect(plan.items.first.suggestedDay, 1);
    expect(plan.items.last.suggestedDay, 3);
    expect(plan.totalMinutes, 75);
  });
}
