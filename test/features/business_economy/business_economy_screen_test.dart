import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/features/business_economy/presentation/auren_business_economy_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('business economy hub exposes the five capability areas',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenBusinessEconomyScreen()),
    );

    expect(find.text('AUREN Business & Economy'), findsOneWidget);
    expect(find.text('Local Business OS'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Business Discovery').first,
      250,
      scrollable: find.descendant(
        of: find.byType(AurenBusinessEconomyScreen),
        matching: find.byType(Scrollable),
      ).first,
    );
    expect(find.text('Business Discovery').first, findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Buyer–Seller Matching').first,
      250,
      scrollable: find.descendant(
        of: find.byType(AurenBusinessEconomyScreen),
        matching: find.byType(Scrollable),
      ).first,
    );
    expect(find.text('Buyer–Seller Matching').first, findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Trade & Export Hub').first,
      250,
      scrollable: find.descendant(
        of: find.byType(AurenBusinessEconomyScreen),
        matching: find.byType(Scrollable),
      ).first,
    );
    expect(find.text('Trade & Export Hub').first, findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Business Growth Planner').first,
      250,
      scrollable: find.descendant(
        of: find.byType(AurenBusinessEconomyScreen),
        matching: find.byType(Scrollable),
      ).first,
    );
    expect(find.text('Business Growth Planner').first, findsOneWidget);
  });

  testWidgets('growth planner opens from the hub', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenBusinessEconomyScreen()),
    );

    await tester.scrollUntilVisible(
      find.text('Business Growth Planner').first,
      250,
      scrollable: find.descendant(
        of: find.byType(AurenBusinessEconomyScreen),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.tap(find.text('Business Growth Planner').first);
    await tester.pumpAndSettle();

    expect(find.text('Business Growth Planner').first, findsOneWidget);
    expect(find.text('حفظ الخطة').first, findsOneWidget);
    expect(find.text('هدف قابل للقياس'), findsOneWidget);
  });

  testWidgets('matching brief is saved locally without sending a request',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenBusinessEconomyScreen()),
    );
    await tester.scrollUntilVisible(
      find.text('Buyer–Seller Matching').first,
      250,
      scrollable: find.descendant(
        of: find.byType(AurenBusinessEconomyScreen),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.tap(find.text('Buyer–Seller Matching'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.decoration?.labelText == 'احتياج المشتري *'),
      'Organic sesame',
    );
    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.decoration?.labelText == 'عرض البائع *'),
      'Organic sesame available',
    );
    // Dismiss the simulated keyboard before scrolling to the save action.
    // Otherwise the bottom inset can leave the button visible but not hittable.
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('حفظ المسودة محلياً').first,
      250,
      scrollable: find.descendant(
        of: find.byType(AurenBuyerSellerMatchDraftScreen),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.tap(find.text('حفظ المسودة محلياً'));
    await tester.pumpAndSettle();

    expect(find.text('تم حفظ المسودة على هذا الجهاز؛ لم يُرسل أي طلب.'),
        findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auren_business_match_draft_v1_need'),
        'Organic sesame');
    expect(prefs.getString('auren_business_match_draft_v1_offer'),
        'Organic sesame available');
  });

  testWidgets('growth planner saves a measurable goal locally', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenBusinessEconomyScreen()),
    );
    await tester.scrollUntilVisible(
      find.text('Business Growth Planner').first,
      250,
      scrollable: find.descendant(
        of: find.byType(AurenBusinessEconomyScreen),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.tap(find.text('Business Growth Planner').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.decoration?.labelText == 'هدف قابل للقياس'),
      'Reach 10 customers',
    );
    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.decoration?.labelText == 'مجموعة العملاء المستهدفة'),
      'Local retailers',
    );
    await tester.scrollUntilVisible(
      find.text('حفظ الخطة').first,
      250,
      scrollable: find.descendant(
        of: find.byType(AurenBusinessGrowthPlannerScreen),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.tap(find.text('حفظ الخطة'));
    await tester.pumpAndSettle();

    expect(find.text('تم حفظ الخطة محلياً.'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auren_business_growth_plan_v1_goal'),
        'Reach 10 customers');
    expect(prefs.getString('auren_business_growth_plan_v1_customers'),
        'Local retailers');
  });
}
