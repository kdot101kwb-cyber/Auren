import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/core/planning/nova_offline_daily_planner.dart';

void main() {
  const planner = NovaOfflineDailyPlanner();

  NovaPlanItem item(
    String id,
    int minutes, {
    NovaPlanPriority priority = NovaPlanPriority.normal,
    bool completed = false,
  }) => NovaPlanItem(
    id: id,
    title: 'Task $id',
    estimatedMinutes: minutes,
    priority: priority,
    isCompleted: completed,
  );

  test('schedules urgent work first within the available time budget', () {
    final plan = planner.build(
      availableMinutes: 90,
      items: [
        item('low', 30, priority: NovaPlanPriority.low),
        item('urgent', 45, priority: NovaPlanPriority.urgent),
        item('normal', 30),
      ],
    );
    expect(plan.scheduled.map((e) => e.id), ['urgent', 'normal']);
    expect(plan.deferred.map((e) => e.id), ['low']);
    expect(plan.usedMinutes, 75);
    expect(plan.remainingMinutes, 15);
  });

  test('completed and invalid items are excluded', () {
    final plan = planner.build(
      availableMinutes: 60,
      items: [
        item('done', 10, completed: true),
        item('zero', 0),
        item('negative', -3),
        item('', 5),
        item('valid', 20),
      ],
    );
    expect(plan.scheduled.map((e) => e.id), ['valid']);
    expect(plan.deferred, isEmpty);
  });

  test('duplicate IDs are included only once', () {
    final plan = planner.build(
      availableMinutes: 60,
      items: [item('same', 10), item('same', 15)],
    );
    expect(plan.scheduled, hasLength(1));
    expect(plan.scheduled.single.estimatedMinutes, 10);
  });

  test('does not exceed the time budget and defers tasks that do not fit', () {
    final plan = planner.build(
      availableMinutes: 20,
      items: [item('a', 15), item('b', 10), item('c', 5)],
    );
    expect(plan.usedMinutes, lessThanOrEqualTo(20));
    expect(plan.scheduled.map((e) => e.id), ['c', 'a']);
    expect(plan.deferred.map((e) => e.id), ['b']);
  });

  test('zero-minute budget defers all pending tasks', () {
    final plan = planner.build(
      availableMinutes: 0,
      items: [item('a', 10)],
    );
    expect(plan.scheduled, isEmpty);
    expect(plan.deferred, hasLength(1));
    expect(plan.remainingMinutes, 0);
  });

  test('negative budget is rejected', () {
    expect(
      () => planner.build(availableMinutes: -1, items: const []),
      throwsArgumentError,
    );
  });
}
