import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/features/transport/domain/mobility_models.dart';
import 'package:auren/features/transport/presentation/transport_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Finder field(String label) => find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.labelText == label,
        description: 'TextField with label $label',
      );

  Future<void> openSection(WidgetTester tester, String title) async {
    await tester.pumpAndSettle();
    final section = find.ancestor(
      of: find.text(title),
      matching: find.byType(ExpansionTile),
    );
    await tester.ensureVisible(section);
    await tester.tap(section);
    await tester.pumpAndSettle();
  }

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
    await openSection(tester, 'Mobility Cost Planner');

    Future<void> enter(String label, String value) async {
      final targetField = field(label);
      await tester.ensureVisible(targetField);
      await tester.enterText(targetField, value);
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
    await openSection(tester, 'Public Transport Intelligence');
    await tester.ensureVisible(find.text('حفظ محليًا'));
    await tester.tap(find.text('حفظ محليًا'));
    await tester.pumpAndSettle();

    expect(find.text('أدخل المشغّل والمسار والتوقفات ومصدرًا واضحًا للمعلومات.'), findsOneWidget);
  });

  testWidgets('cargo draft records selected status and delivery requirements', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenTransportScreen()));
    await openSection(tester, 'Freight & Cargo Coordination');

    await tester.enterText(field('مرجع الشحنة'), 'C-101');
    await tester.enterText(field('من'), 'بورتسودان');
    await tester.enterText(field('إلى'), 'الخرطوم');
    await tester.enterText(
      field('متطلبات التسليم، مفصولة بفواصل (اختياري)'),
      'تغليف, توقيع المستلم',
    );

    await tester.ensureVisible(find.byType(DropdownButtonFormField<CargoStatus>));
    await tester.tap(find.byType(DropdownButtonFormField<CargoStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('قيد النقل').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('حفظ مسودة الشحنة'));
    await tester.tap(find.text('حفظ مسودة الشحنة'));
    await tester.pumpAndSettle();

    expect(find.textContaining('C-101: بورتسودان → الخرطوم • قيد النقل'), findsOneWidget);
    expect(find.textContaining('تغليف, توقيع المستلم'), findsOneWidget);
  });

  testWidgets('vehicle records surface insurance and maintenance alerts', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenTransportScreen()));
    await openSection(tester, 'Vehicle Ownership');

    final today = DateTime.now();
    final soon = today.add(const Duration(days: 1));
    final overdue = today.subtract(const Duration(days: 1));
    String date(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

    await tester.enterText(field('الشركة / الصانع'), 'Toyota');
    await tester.enterText(field('الطراز'), 'Corolla');
    await tester.enterText(field('سنة الصنع'), '2020');
    await tester.enterText(
      field('انتهاء التأمين YYYY-MM-DD (اختياري)'),
      date(soon),
    );
    await tester.enterText(
      field('موعد الصيانة YYYY-MM-DD (اختياري)'),
      date(overdue),
    );

    await tester.ensureVisible(find.text('إضافة مركبة'));
    await tester.tap(find.text('إضافة مركبة'));
    await tester.pumpAndSettle();

    expect(find.textContaining('تنبيه: التأمين يحتاج مراجعة'), findsOneWidget);
    expect(find.textContaining('تنبيه: موعد الصيانة حان أو فات'), findsOneWidget);
  });
}
