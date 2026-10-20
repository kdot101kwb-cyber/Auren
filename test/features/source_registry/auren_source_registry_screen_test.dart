import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/features/source_registry/presentation/auren_source_registry_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Source Registry stores a source with an explicit review state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenSourceRegistryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('لا توجد مصادر محفوظة'), findsOneWidget);
    await tester.tap(find.text('إضافة مصدر'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'تقرير التجارة');
    await tester.enterText(fields.at(1), 'https://example.org/trade-report');
    await tester.tap(find.text('حفظ المصدر'));
    await tester.pumpAndSettle();

    expect(find.text('تقرير التجارة'), findsOneWidget);
    expect(find.text('بحاجة للمراجعة'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('auren_source_registry_v1'),
      contains('https://example.org/trade-report'),
    );
  });

  testWidgets('Source Registry distinguishes review state from verification', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenSourceRegistryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('وليست تحققاً آلياً'), findsOneWidget);
  });
}
