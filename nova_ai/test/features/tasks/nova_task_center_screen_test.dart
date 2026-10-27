import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/tasks/nova_task_center_screen.dart';
import 'package:nova_ai/firebase_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NovaFirebaseRuntime.initialized = false;
    NovaFirebaseRuntime.appCheckActivated = false;
    NovaFirebaseRuntime.initializationError = 'Firebase disabled in offline test';
  });

  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: NovaTaskCenterScreen()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('task submitted without Firebase is saved locally and restored',
      (tester) async {
    await openScreen(tester);

    await tester.enterText(find.byType(TextField), 'Prepare a no-budget revenue plan');
    await tester.tap(find.text('إرسال المهمة للخادم'));
    await tester.pumpAndSettle();

    expect(find.textContaining('حُفظت المهمة محلياً كمسودة'), findsOneWidget);
    expect(find.text('المسودات المحلية: 1'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('nova.task_center.offline_drafts.v1');
    expect(raw, isNotNull);
    expect(raw, hasLength(1));
    final draft = jsonDecode(raw!.single) as Map<String, dynamic>;
    expect(draft['prompt'], 'Prepare a no-budget revenue plan');
    expect(draft['type'], 'research');
    expect(draft['status'], 'offline_draft');

    await tester.pumpWidget(const SizedBox.shrink());
    await openScreen(tester);
    expect(find.text('المسودات المحلية: 1'), findsOneWidget);
    expect(find.textContaining('Prepare a no-budget revenue plan'), findsOneWidget);
  });

  testWidgets('local draft can be deleted from the device', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('nova.task_center.offline_drafts.v1', [
      jsonEncode({
        'id': 'test-draft-1',
        'type': 'research',
        'prompt': 'Delete this local draft',
        'createdAt': '2026-10-27T00:00:00.000Z',
        'status': 'offline_draft',
      }),
    ]);

    await openScreen(tester);
    expect(find.textContaining('Delete this local draft'), findsOneWidget);
    await tester.tap(find.byTooltip('حذف المسودة'));
    await tester.pumpAndSettle();

    expect(find.text('المسودات المحلية: 0'), findsOneWidget);
    expect(prefs.getStringList('nova.task_center.offline_drafts.v1') ?? const <String>[], isEmpty);
  });
}
