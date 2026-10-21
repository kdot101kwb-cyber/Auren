import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/transport/presentation/transport_screen.dart';

void main() {
  testWidgets('shows five separate mobility workspaces', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenTransportScreen()));

    expect(find.text('Public Transport Intelligence'), findsOneWidget);
    expect(find.text('Vehicle Ownership'), findsOneWidget);
    expect(find.text('Mobility Cost Planner'), findsOneWidget);
    expect(find.text('Freight & Cargo Coordination'), findsOneWidget);
    expect(find.text('Maritime & Port Intelligence'), findsOneWidget);
  });

  testWidgets('cost planner calculates only from explicit inputs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenTransportScreen()));
    await tester.tap(find.text('Mobility Cost Planner'));
    await tester.pumpAndSettle();

    Future<void> enter(String label, String value) async {
      final field = find.widgetWithText(TextField, label);
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
    }

    await enter('المسافة لكل رحلة (كم)', '100');
    await enter('عدد الرحلات', '2');
    await enter('استهلاك الوقود (لتر / 100 كم)', '8');
    await enter('سعر لتر الوقود', '1.5');
    await enter('رسوم الطريق لكل رحلة', '2');
    await enter('مواقف لكل رحلة', '3');
    await enter('تكاليف أخرى لكل رحلة', '1');
    await enter('العملة', 'SDG');

    await tester.ensureVisible(find.text('احسب التقدير'));
    await tester.tap(find.text('احسب التقدير'));
    await tester.pumpAndSettle();

    expect(find.text('الإجمالي التقديري: 36.00 SDG'), findsOneWidget);
    expect(find.text('الوقود: 24.00 SDG'), findsOneWidget);
  });

  testWidgets('requires a named source before recording a transit route', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenTransportScreen()));
    await tester.tap(find.text('Public Transport Intelligence'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('حفظ محليًا'));
    await tester.tap(find.text('حفظ محليًا'));
    await tester.pumpAndSettle();

    expect(find.text('أدخل المشغّل والمسار والتوقفات ومصدرًا واضحًا للمعلومات.'), findsOneWidget);
  });
}
