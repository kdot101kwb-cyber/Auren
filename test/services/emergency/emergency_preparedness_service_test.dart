import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/services/emergency/emergency_preparedness_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults are copied and checklist completion persists per area', () async {
    final service = AurenEmergencyPreparednessService();
    final first = await service.tasksFor('Khartoum, Sudan');
    expect(first, hasLength(4));
    expect(first.first.completed, isFalse);

    await service.setCompleted(
      area: 'Khartoum, Sudan',
      taskId: 'trusted_contact',
      completed: true,
    );

    final restored = await service.tasksFor('Khartoum, Sudan');
    expect(restored.first.completed, isTrue);
    expect((await service.tasksFor('Port Sudan, Sudan')).first.completed, isFalse);
  });

  test('rejects unknown task IDs and blank area labels', () async {
    final service = AurenEmergencyPreparednessService();
    await expectLater(
      service.tasksFor('  '),
      throwsArgumentError,
    );
    await expectLater(
      service.setCompleted(
        area: 'Khartoum',
        taskId: 'not_a_real_task',
        completed: true,
      ),
      throwsArgumentError,
    );
  });

  test('malformed stored JSON falls back to safe defaults', () async {
    SharedPreferences.setMockInitialValues({
      'auren.emergency_preparedness.v1.khártoum': '{broken',
    });
    final service = AurenEmergencyPreparednessService();
    expect(await service.tasksFor('Khártoum'), hasLength(4));
  });
}
