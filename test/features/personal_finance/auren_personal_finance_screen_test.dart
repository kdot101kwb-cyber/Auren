import 'package:auren/features/personal_finance/presentation/auren_personal_finance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpFinanceScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: AurenPersonalFinanceScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a zeroed summary and empty-state guidance', (tester) async {
    await pumpFinanceScreen(tester);

    expect(find.text('أموالي وميزانيتي'), findsOneWidget);
    expect(find.text('الصافي المسجّل'), findsOneWidget);
    expect(find.text('لسه ما سجلت أي حركة'), findsOneWidget);
    expect(find.text('المتبقي 100000.00 SDG'), findsOneWidget);
  });

  testWidgets('records an expense and updates monthly budget summary', (tester) async {
    await pumpFinanceScreen(tester);

    await tester.tap(find.text('تسجيل حركة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('finance-entry-amount')), '250');
    await tester.enterText(find.widgetWithText(TextFormField, 'التصنيف (مثلاً: طعام)'), 'طعام');
    await tester.tap(find.text('حفظ الحركة'));
    await tester.pumpAndSettle();

    expect(find.text('طعام'), findsOneWidget);
    expect(find.text('المتبقي 99750.00 SDG'), findsOneWidget);
    expect(find.text('−250.00 SDG'), findsOneWidget);
  });

  testWidgets('records income and keeps net total consistent', (tester) async {
    await pumpFinanceScreen(tester);

    await tester.tap(find.text('تسجيل حركة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('دخل'));
    await tester.enterText(find.byKey(const Key('finance-entry-amount')), '1000');
    await tester.enterText(find.widgetWithText(TextFormField, 'التصنيف (مثلاً: طعام)'), 'راتب');
    await tester.tap(find.text('حفظ الحركة'));
    await tester.pumpAndSettle();

    expect(find.text('راتب'), findsOneWidget);
    expect(find.text('+1000.00 SDG'), findsOneWidget);
    expect(find.text('1000.00 SDG'), findsOneWidget);
  });

  testWidgets('rejects zero amount without closing the entry form', (tester) async {
    await pumpFinanceScreen(tester);

    await tester.tap(find.text('تسجيل حركة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('finance-entry-amount')), '0');
    await tester.enterText(find.widgetWithText(TextFormField, 'التصنيف (مثلاً: طعام)'), 'طعام');
    await tester.tap(find.text('حفظ الحركة'));
    await tester.pumpAndSettle();

    expect(find.text('أدخل مبلغاً صحيحاً أكبر من صفر'), findsOneWidget);
    expect(find.text('تسجيل حركة مالية'), findsOneWidget);
  });
}
