import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/features/engineering/nova_engineering_orchestrator.dart';
import 'package:nova_ai/features/engineering/nova_engineering_task_queue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists a planned task and reloads it from device storage', () async {
    final queue = NovaEngineeringTaskQueue();
    const orchestrator = NovaEngineeringOrchestrator();
    final assignment = orchestrator.plan('Fix Flutter screen and APK build');

    final saved = await queue.enqueue(assignment);
    final loaded = await NovaEngineeringTaskQueue().load();

    expect(loaded, hasLength(1));
    expect(loaded.single.id, saved.id);
    expect(loaded.single.goal, assignment.goal);
    expect(loaded.single.roles, contains(NovaEngineeringRole.flutterUi.name));
    expect(loaded.single.status, NovaEngineeringTaskStatus.planned.name);
    expect(loaded.single.requiresHumanApproval, isTrue);
    expect(loaded.single.acceptanceCriteria, contains('فحص الملفات الفعلية وتحديد نطاق التغيير قبل التعديل.'));
    expect(loaded.single.acceptanceCriteria, contains('التحقق من نتيجة بناء Android/CI إن كانت البيئة متاحة.'));
  });

  test('status updates are persisted and unknown task ids are rejected', () async {
    final queue = NovaEngineeringTaskQueue();
    final assignment = const NovaEngineeringOrchestrator().plan('Improve the project');
    final saved = await queue.enqueue(assignment);

    expect(
      await queue.updateStatus(saved.id, NovaEngineeringTaskStatus.awaitingApproval),
      isTrue,
    );
    expect(await queue.updateStatus('missing-id', NovaEngineeringTaskStatus.completed), isFalse);
    expect(
      (await queue.load()).single.status,
      NovaEngineeringTaskStatus.awaitingApproval.name,
    );
  });

  test('empty queue loads safely', () async {
    expect(await NovaEngineeringTaskQueue().load(), isEmpty);
  });
}
