import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/tasks/nova_task_milestone_tracker.dart';

void main() {
  group('NovaTaskMilestoneTracker', () {
    test('keeps the initial snapshot silent', () {
      final tracker = NovaTaskMilestoneTracker();

      final milestones = tracker.update([
        {'taskId': 'task-1', 'type': 'research', 'status': 'completed'},
        {'taskId': 'task-2', 'type': 'plan', 'status': 'failed'},
      ]);

      expect(milestones, isEmpty);
    });

    test('reports a newly completed task only once', () {
      final tracker = NovaTaskMilestoneTracker();
      tracker.update([
        {'taskId': 'task-1', 'type': 'research', 'status': 'running'},
      ]);

      final milestones = tracker.update([
        {'taskId': 'task-1', 'type': 'research', 'status': 'succeeded'},
      ]);

      expect(milestones, hasLength(1));
      expect(milestones.single.isSuccess, isTrue);
      expect(milestones.single.status, 'succeeded');
      expect(milestones.single.message, contains('اكتملت research'));

      expect(
        tracker.update([
          {'taskId': 'task-1', 'type': 'research', 'status': 'succeeded'},
        ]),
        isEmpty,
      );
    });

    test('reports failure, blocker, and approval transitions', () {
      final tracker = NovaTaskMilestoneTracker();
      tracker.update([
        {'taskId': 'a', 'status': 'running'},
        {'taskId': 'b', 'status': 'running'},
        {'taskId': 'c', 'status': 'running'},
      ]);

      final milestones = tracker.update([
        {'taskId': 'a', 'status': 'failed'},
        {'taskId': 'b', 'status': 'blocked'},
        {'taskId': 'c', 'status': 'awaiting_approval'},
      ]);

      expect(milestones.map((item) => item.status),
          ['failed', 'blocked', 'awaiting_approval']);
      expect(milestones.every((item) => !item.isSuccess), isTrue);
    });

    test('does not lose known states when a task is absent from a page', () {
      final tracker = NovaTaskMilestoneTracker();
      tracker.update([
        {'taskId': 'task-1', 'status': 'running'},
      ]);

      tracker.update([
        {'taskId': 'another-task', 'status': 'running'},
      ]);

      final milestones = tracker.update([
        {'taskId': 'task-1', 'status': 'completed'},
      ]);

      expect(milestones, hasLength(1));
      expect(milestones.single.taskId, 'task-1');
    });

    test('ignores malformed task identifiers and non-milestone states', () {
      final tracker = NovaTaskMilestoneTracker();
      tracker.update([
        {'taskId': 'task-1', 'status': 'running'},
      ]);

      expect(
        tracker.update([
          {'taskId': '', 'status': 'completed'},
          {'taskId': 'task-1', 'status': 'queued'},
        ]),
        isEmpty,
      );
    });
  });
}
