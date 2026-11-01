import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/core/offline/nova_local_workspace_store.dart';
import 'package:nova_ai/features/workspace/nova_workspace_screen.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('workspace shows empty state and adds a local task', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = NovaLocalWorkspaceStore(preferences: preferences);

    await tester.pumpWidget(MaterialApp(home: NovaWorkspaceScreen(store: store)));
    await tester.pumpAndSettle();
    expect(find.text('مساحة العمل فارغة. أضف أول مهمة.'), findsOneWidget);

    await tester.tap(find.text('مهمة جديدة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'مراجعة فرصة جديدة');
    await tester.tap(find.text('حفظ محلياً'));
    await tester.pumpAndSettle();

    expect(find.text('مراجعة فرصة جديدة'), findsOneWidget);
    expect(await store.loadTasks(), hasLength(1));
  });
}
