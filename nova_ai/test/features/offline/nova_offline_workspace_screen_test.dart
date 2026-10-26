import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/features/offline/nova_offline_workspace_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('saves an offline plan locally and reloads it', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NovaOfflineWorkspaceScreen())));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'خطة دخل من صناعة الفيديو');
    await tester.enterText(find.byType(TextField).last, 'إعداد نموذج أولي دون اتصال');
    await tester.tap(find.text('حفظ محلياً'));
    await tester.pumpAndSettle();

    expect(find.text('خطة دخل من صناعة الفيديو'), findsOneWidget);
    expect(find.textContaining('حُفظت الملاحظة على هذا الجهاز فقط.'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('nova.offline.workspace.v1'), contains('خطة دخل من صناعة الفيديو'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NovaOfflineWorkspaceScreen())));
    await tester.pumpAndSettle();
    expect(find.text('خطة دخل من صناعة الفيديو'), findsOneWidget);
  });

  testWidgets('requires a title before saving', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NovaOfflineWorkspaceScreen())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('حفظ محلياً'));
    await tester.pumpAndSettle();
    expect(find.text('اكتب عنواناً قبل الحفظ.'), findsOneWidget);
  });
}
