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
    final saveButton = find.text('حفظ في مساحة AUREN');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    // The form and saved-item history share a scrollable viewport; the newly
    // saved card may be below the fold and not built until scrolled into view.
    await tester.scrollUntilVisible(
      find.text('إضافة مزامنة منخفضة البيانات'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('إضافة مزامنة منخفضة البيانات'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('دراسة خيارات التخزين والعمل دون اتصال.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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

    await tester.tap(find.text('فتح مهندس بناء التطبيقات'));
    expect(opened, isTrue);
  });
}
