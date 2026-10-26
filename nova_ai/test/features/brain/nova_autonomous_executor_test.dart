import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/brain/nova_autonomous_brain.dart';
import 'package:nova_ai/features/brain/nova_autonomous_executor.dart';

class _FakeAdapter implements NovaExecutionAdapter {
  _FakeAdapter(this.handler);

  final Future<NovaExecutionResult> Function(NovaBrainStep step) handler;
  int calls = 0;

  @override
  bool canExecute(NovaBrainStep step) => true;

  @override
  Future<NovaExecutionResult> execute(NovaBrainStep step) {
    calls++;
    return handler(step);
  }
}

void main() {
  const planner = NovaAutonomousPlanner();

  test('executor requires evidence before marking a step successful', () async {
    final task = planner.plan('مهمة عامة');
    final adapter = _FakeAdapter(
      (_) async => const NovaExecutionResult(
        success: true,
        summary: 'الأداة قالت إنها نجحت',
      ),
    );

    final report = await NovaAutonomousExecutor(
      adapters: [adapter],
      maxAttemptsPerStep: 2,
    ).run(task);

    expect(adapter.calls, 2);
    expect(report.attempts, 2);
    expect(report.task.steps.first.status, NovaStepStatus.failed);
    expect(report.task.steps.first.evidence, contains('لم يثبت النجاح'));
    expect(report.task.completedSteps, 0);
  });

  test('executor retries failures but accepts verified evidence', () async {
    final task = planner.plan('مهمة عامة');
    final adapter = _FakeAdapter((_) async {
      if (adapterCalls++ == 0) {
        return const NovaExecutionResult(
          success: false,
          summary: 'محاولة أولى فاشلة',
        );
      }
      return const NovaExecutionResult(
        success: true,
        summary: 'التحقق نجح',
        evidence: 'https://example.com/run/123',
      );
    });

    final report = await NovaAutonomousExecutor(
      adapters: [adapter],
      maxAttemptsPerStep: 2,
    ).run(task);

    expect(report.attempts, 2);
    expect(report.task.steps.first.status, NovaStepStatus.succeeded);
    expect(report.task.steps.first.evidence, contains('https://example.com/run/123'));
  });

  test('executor blocks when no adapter supports a step', () async {
    final task = planner.plan('مهمة عامة');
    final report = await const NovaAutonomousExecutor(
      adapters: [],
    ).run(task);

    expect(report.attempts, 0);
    expect(report.task.steps.first.status, NovaStepStatus.blocked);
    expect(report.task.steps.first.evidence, contains('لا توجد أداة'));
  });

  test('executor stops after the configured retry limit', () async {
    final task = planner.plan('مهمة عامة');
    final adapter = _FakeAdapter(
      (_) async => const NovaExecutionResult(
        success: false,
        summary: 'فشل',
      ),
    );

    final report = await NovaAutonomousExecutor(
      adapters: [adapter],
      maxAttemptsPerStep: 3,
    ).run(task);

    expect(adapter.calls, 3);
    expect(report.task.steps.first.status, NovaStepStatus.failed);
    expect(report.task.steps[1].status, NovaStepStatus.pending);
  });
}

var adapterCalls = 0;
