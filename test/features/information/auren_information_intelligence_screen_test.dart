import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auren/features/information/presentation/auren_information_intelligence_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows five distinct information tools', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenInformationIntelligenceScreen()));
    await tester.pumpAndSettle();

    expect(find.text('AUREN Information Tools'), findsOneWidget);
    expect(find.text('الاستشهادات'), findsOneWidget);
    expect(find.text('متابعة المواضيع'), findsOneWidget);
    expect(find.text('حداثة المصادر'), findsOneWidget);
    expect(find.text('حزم دون اتصال'), findsOneWidget);
    expect(find.text('تاريخ المعرفة'), findsOneWidget);
  });

  testWidgets('citation tool generates a copyable citation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenInformationIntelligenceScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == 'عنوان المصدر *',
    ), 'Test source');
    await tester.tap(find.text('إنشاء الاستشهاد'));
    await tester.pumpAndSettle();

    expect(find.text('الاستشهاد الناتج'), findsOneWidget);
    expect(find.text('Test source.'), findsOneWidget);
  });
}
