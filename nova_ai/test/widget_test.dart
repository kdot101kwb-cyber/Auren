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
    await tester.ensureVisible(task);
    await tester.pumpAndSettle();
    final checkbox = find.ancestor(of: task, matching: find.byType(CheckboxListTile));
    expect(checkbox, findsOneWidget);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const NovaApp());
    await tester.pumpAndSettle();

    final restartedCheckbox = find.ancestor(of: task, matching: find.byType(CheckboxListTile));
    final tile = tester.widget<CheckboxListTile>(restartedCheckbox);
    expect(tile.value, isTrue);
  });
}
