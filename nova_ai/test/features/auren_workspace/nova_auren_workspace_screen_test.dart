import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/features/auren_workspace/nova_auren_workspace_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('workspace records and displays a private AUREN idea', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: NovaAurenWorkspaceScreen(onOpenBuilder: () {})),
    ));
    await tester.pumpAndSettle();

    expect(find.text('مساحة NOVA الخاصة بـ AUREN'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).first,
      'إضافة مزامنة منخفضة البيانات',
    );
    await tester.enterText(
      find.byType(TextField).last,
      'دراسة خيارات التخزين والعمل دون اتصال.',
    );
    await tester.tap(find.text('حفظ في مساحة AUREN'));
    await tester.pumpAndSettle();

    expect(find.text('إضافة مزامنة منخفضة البيانات'), findsOneWidget);
    expect(find.text('دراسة خيارات التخزين والعمل دون اتصال.'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('nova.auren.workspace.items.v1'), contains('إضافة مزامنة منخفضة البيانات'));
  });

  testWidgets('workspace builder shortcut invokes callback', (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: NovaAurenWorkspaceScreen(onOpenBuilder: () => opened = true)),
    ));
    await tester.pumpAndSettle();

    final builderShortcut = find.text('فتح مهندس بناء التطبيقات');
    await tester.ensureVisible(builderShortcut);
    await tester.pumpAndSettle();
    await tester.tap(builderShortcut);
    expect(opened, isTrue);
  });
}
