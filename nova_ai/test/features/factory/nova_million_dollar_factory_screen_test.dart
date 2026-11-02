import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/features/factory/nova_million_dollar_factory_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('factory explains the first zero-budget pilot', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: NovaMillionDollarFactoryScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('NOVA AI MILLION DOLLAR FACTORY'), findsOneWidget);
    expect(find.textContaining('Sudanese Arabic AI localization'), findsOneWidget);
    expect(find.textContaining('لا توجد أرباح مضمونة'), findsOneWidget);
    expect(find.text('0 من 4 خطوات مكتملة'), findsOneWidget);
  });

  testWidgets('factory stores a lead and received payment locally',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: NovaMillionDollarFactoryScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).at(0),
      'Example AI research team',
    );
    await tester.tap(find.text('إضافة إلى القائمة المحلية'));
    await tester.pumpAndSettle();
    expect(find.text('Example AI research team'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '12.50');
    await tester.tap(find.text('تسجيل دفعة مستلمة'));
    await tester.pumpAndSettle();
    expect(find.textContaining('USD 12.50'), findsOneWidget);
    expect(find.textContaining('سُجل المبلغ'), findsOneWidget);
  });

  testWidgets('factory rejects zero as a received payment', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: NovaMillionDollarFactoryScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), '0');
    await tester.tap(find.text('تسجيل دفعة مستلمة'));
    await tester.pumpAndSettle();
    expect(find.text('أدخل مبلغاً مستلماً صحيحاً أكبر من صفر.'),
        findsOneWidget);
  });
}
