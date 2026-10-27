import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('NOVA dashboard exposes main sections', (tester) async {
    await tester.pumpWidget(const NovaApp());
    expect(find.text('NOVA AI'), findsOneWidget);
    expect(find.text('مركز القيادة الذكي'), findsOneWidget);
    expect(find.text('الوكلاء'), findsWidgets);
    expect(find.text('فرص الدخل'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('dashboard task completion survives app restart', (tester) async {
    await tester.pumpWidget(const NovaApp());
    await tester.pumpAndSettle();

    final task = find.text('فحص حالة مستودع AUREN');
    await tester.scrollUntilVisible(task, 250, scrollable: find.byType(Scrollable).first);
    final checkbox = find.ancestor(of: task, matching: find.byType(CheckboxListTile));
    expect(checkbox, findsOneWidget);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const NovaApp());
    await tester.pumpAndSettle();

    final restartedTask = find.text('فحص حالة مستودع AUREN');
    await tester.scrollUntilVisible(restartedTask, 250, scrollable: find.byType(Scrollable).first);
    final restartedCheckbox = find.ancestor(of: restartedTask, matching: find.byType(CheckboxListTile));
    final tile = tester.widget<CheckboxListTile>(restartedCheckbox);
    expect(tile.value, isTrue);
  });


  testWidgets('wallet ledger records a local income entry', (tester) async {
    await tester.pumpWidget(const NovaApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('كل أقسام NOVA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('دفتر الدخل والمصروفات'));
    await tester.pumpAndSettle();

    expect(find.text('دفتر الدخل والمصروفات'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'مبلغ'),
      '125.50',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'ملاحظة أو مرجع إيصال (اختياري)'),
      'اختبار دخل',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('تسجيل العملية'));
    await tester.tap(find.text('تسجيل العملية'));
    await tester.pumpAndSettle();

    expect(find.textContaining('125.5 SDG'), findsOneWidget);
    expect(find.text('اختبار دخل'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getStringList('nova.wallet.ledger.v1'),
      isNotEmpty,
    );
  });
}