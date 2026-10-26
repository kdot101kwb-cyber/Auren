import 'nova_autonomous_brain.dart';

/// Result returned by a real tool adapter. A successful result must include
/// concrete evidence (for example a CI run URL or a verified artifact path).
class NovaExecutionResult {
  const NovaExecutionResult({
    required this.success,
    required this.summary,
    this.evidence = '',
  });

  final bool success;
  final String summary;
  final String evidence;
}

/// A tool adapter performs one step using an explicitly configured capability.
/// Apps must not place GitHub tokens, API keys, or other secrets in adapters
/// compiled into a mobile client.
abstract interface class NovaExecutionAdapter {
  bool canExecute(NovaBrainStep step);

  Future<NovaExecutionResult> execute(NovaBrainStep step);
}

class NovaExecutionReport {
  const NovaExecutionReport({
    required this.task,
    required this.attempts,
    required this.messages,
  });

  final NovaBrainTask task;
  final int attempts;
  final List<String> messages;
}

/// Bounded, sequential executor. It never marks a step successful without
/// evidence, never loops indefinitely, and stops when no adapter can handle
/// the next pending step. This is orchestration infrastructure, not a claim
/// that any external capability exists until a real adapter is registered.
class NovaAutonomousExecutor {
  const NovaAutonomousExecutor({
    required this.adapters,
    this.maxAttemptsPerStep = 2,
  }) : assert(maxAttemptsPerStep > 0);

  final List<NovaExecutionAdapter> adapters;
  final int maxAttemptsPerStep;

  Future<NovaExecutionReport> run(
    NovaBrainTask initialTask, {
    bool Function()? shouldStop,
  }) async {
    var task = initialTask;
    var attempts = 0;
    final messages = <String>[];

    for (var index = 0; index < task.steps.length; index++) {
      if (shouldStop?.call() ?? false) {
        messages.add('توقف التنفيذ بطلب الإيقاف.');
        break;
      }

      final step = task.steps[index];
      if (step.status == NovaStepStatus.succeeded) continue;

      NovaExecutionAdapter? adapter;
      for (final candidate in adapters) {
        if (candidate.canExecute(step)) {
          adapter = candidate;
          break;
        }
      }

      if (adapter == null) {
        task = _replaceStep(
          task,
          index,
          step.copyWith(
            status: NovaStepStatus.blocked,
            evidence: 'لا توجد أداة تنفيذ موصولة لهذه الخطوة.',
          ),
        );
        messages.add('توقفت عند: ${step.title}. لا يوجد محرك مناسب.');
        break;
      }

      var completed = false;
      var cancelled = false;
      for (var attempt = 1; attempt <= maxAttemptsPerStep; attempt++) {
        if (shouldStop?.call() ?? false) {
          cancelled = true;
          messages.add('توقف التنفيذ بطلب الإيقاف.');
          break;
        }

        attempts++;
        task = _replaceStep(
          task,
          index,
          step.copyWith(status: NovaStepStatus.running, evidence: ''),
        );

        try {
          final result = await adapter.execute(step);
          if (result.success && result.evidence.trim().isNotEmpty) {
            task = _replaceStep(
              task,
              index,
              step.copyWith(
                status: NovaStepStatus.succeeded,
                evidence: '${result.summary.trim()} — ${result.evidence.trim()}',
              ),
            );
            messages.add('تم التحقق: ${step.title}');
            completed = true;
            break;
          }

          messages.add(
            'المحاولة $attempt لم تثبت النجاح في "${step.title}": '
            '${result.summary}',
          );
        } catch (error) {
          messages.add(
            'فشلت المحاولة $attempt في "${step.title}": $error',
          );
        }
      }

      if (cancelled) {
        task = _replaceStep(
          task,
          index,
          step.copyWith(
            status: NovaStepStatus.pending,
            evidence: 'أوقف المستخدم التنفيذ؛ لم تُعتمد نتيجة لهذه الخطوة.',
          ),
        );
        break;
      }

      if (!completed) {
        task = _replaceStep(
          task,
          index,
          step.copyWith(
            status: NovaStepStatus.failed,
            evidence: 'لم يثبت النجاح بعد $maxAttemptsPerStep محاولة.',
          ),
        );
        messages.add('توقف التنفيذ عند الخطوة الفاشلة ولم يتجاوزها.');
        break;
      }
    }

    return NovaExecutionReport(
      task: task,
      attempts: attempts,
      messages: List.unmodifiable(messages),
    );
  }

  NovaBrainTask _replaceStep(
    NovaBrainTask task,
    int index,
    NovaBrainStep replacement,
  ) {
    final steps = [...task.steps];
    steps[index] = replacement;
    return task.copyWith(steps: steps);
  }
}
