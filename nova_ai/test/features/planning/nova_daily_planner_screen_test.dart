import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/core/offline/nova_local_workspace_store.dart';
import 'package:nova_ai/features/planning/nova_daily_planner_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('planner creates a bounded plan from local workspace tasks', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = NovaLocalWorkspaceStore(preferences: prefs);
    final now = DateTime.utc(2026, 11, 1);
    for (final id in ['one', 'two', 'three']) {
      await store.saveTask(NovaWorkspaceTask(
        id: id,
        title: 'Task $id',
        createdAt: now,
        updatedAt: now,
      ));
    }

    await tester.pumpWidget(MaterialApp(home: NovaDailyPlannerScreen(store: store)));
    await tester.pumpAndSettle();
    final buildPlanButton = find.text('أنشئ خطة اليوم');
    await tester.ensureVisible(buildPlanButton);
    await tester.tap(buildPlanButton);
    await tester.pumpAndSettle();

    expect(find.text('ابدأ بهذه المهام'), findsOneWidget);
    expect(find.text('مجدول'), findsOneWidget);
    expect(find.text('الخطة اقتراح زمني محلي فقط. لا تبدأ المهام ولا تشغّل وكلاء NOVA تلقائياً.'), findsOneWidget);
  });
}
