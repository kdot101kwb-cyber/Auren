import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/brain/nova_autonomous_brain.dart';

void main() {
  const planner = NovaAutonomousPlanner();

  group('NovaAutonomousPlanner', () {
    test('rejects an empty goal', () {
      expect(() => planner.plan('  '), throwsArgumentError);
    });

    test('creates a software plan with verification steps', () {
      final task = planner.plan(
        'افحص تطبيق Flutter وأصلح فشل البناء',
        now: DateTime.utc(2026, 10, 26),
      );

      expect(task.goal, 'افحص تطبيق Flutter وأصلح فشل البناء');
      expect(task.steps.length, greaterThanOrEqualTo(6));
      expect(
        task.steps.any((step) => step.title.contains('الاختبارات والبناء')),
        isTrue,
      );
      expect(task.isComplete, isFalse);
      expect(task.completedSteps, 0);
    });

    test('creates a content plan without promising virality', () {
      final task = planner.plan('اكتشف ترند فيديو وأنشئ محتوى');

      expect(task.steps.any((step) => step.title.contains('إشارات')), isTrue);
      expect(task.steps.any((step) => step.title.contains('قياس الأداء')), isTrue);
      expect(task.steps.last.title, 'إعداد تقرير التنفيذ');
    });
  });

  group('task persistence codec', () {
    test('round trips task steps and evidence', () {
      final original = planner.plan(
        'افحص بناء التطبيق',
        now: DateTime.utc(2026, 10, 26),
      );
      final firstStep = original.steps.first.copyWith(
        status: NovaStepStatus.succeeded,
        evidence: 'https://github.com/example/actions/runs/1',
      );
      final saved = original.copyWith(
        steps: [firstStep, ...original.steps.skip(1)],
      );

      final decoded = decodeNovaBrainTasks(encodeNovaBrainTasks([saved]));

      expect(decoded, hasLength(1));
      expect(decoded.single.id, saved.id);
      expect(decoded.single.steps.first.status, NovaStepStatus.succeeded);
      expect(
        decoded.single.steps.first.evidence,
        'https://github.com/example/actions/runs/1',
      );
      expect(decoded.single.isComplete, isFalse);
    });

    test('returns an empty list for missing or malformed data', () {
      expect(decodeNovaBrainTasks(null), isEmpty);
      expect(decodeNovaBrainTasks('not-json'), isEmpty);
      expect(decodeNovaBrainTasks('{}'), isEmpty);
    });
  });
}
