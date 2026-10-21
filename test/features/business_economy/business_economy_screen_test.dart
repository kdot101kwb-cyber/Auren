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
      find.text('Business Discovery'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Business Discovery'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Buyer–Seller Matching'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Buyer–Seller Matching'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Trade & Export Hub'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Trade & Export Hub'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Business Growth Planner'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Business Growth Planner'), findsOneWidget);
  });

  testWidgets('growth planner opens from the hub', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenBusinessEconomyScreen()),
    );

    await tester.scrollUntilVisible(
      find.text('Business Growth Planner'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Business Growth Planner'));
    await tester.pumpAndSettle();

    expect(find.text('Business Growth Planner'), findsOneWidget);
    expect(find.text('حفظ الخطة'), findsOneWidget);
    expect(find.text('هدف قابل للقياس'), findsOneWidget);
  });
}
