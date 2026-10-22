import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/features/transport/data/mobility_local_store.dart';
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

  Future<void> enterField(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    final target = field(label);
    await tester.ensureVisible(target);
    await tester.enterText(target, value);
    tester.testTextInput.hide();
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

    await enterField(tester, 'المسافة لكل رحلة (كم)', '100');
    await enterField(tester, 'عدد الرحلات', '2');
    await enterField(tester, 'استهلاك الوقود (لتر / 100 كم)', '8');
    await enterField(tester, 'سعر لتر الوقود', '1.5');
    await enterField(tester, 'رسوم الطريق لكل رحلة', '2');
    await enterField(tester, 'مواقف لكل رحلة', '3');
    await enterField(tester, 'تكاليف أخرى لكل رحلة', '1');
    await enterField(tester, 'العملة', 'SDG');

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

    await enterField(tester, 'مرجع الشحنة', 'C-101');
    await enterField(tester, 'من', 'بورتسودان');
    await enterField(tester, 'إلى', 'الخرطوم');
    await enterField(tester, 'الناقل (اختياري)', 'ناقل تجريبي');
    await enterField(
      tester,
      'متطلبات التسليم، مفصولة بفواصل (اختياري)',
      'تغليف, توقيع المستلم',
    );
    await enterField(tester, 'ملاحظات (اختياري)', 'اتصل قبل الوصول');

    await tester.ensureVisible(find.byType(DropdownButtonFormField<CargoStatus>));
    await tester.tap(find.byType(DropdownButtonFormField<CargoStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('قيد النقل').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('حفظ مسودة الشحنة'));
    await tester.tap(find.text('حفظ مسودة الشحنة'));
    await tester.pumpAndSettle();

    expect(find.textContaining('C-101: بورتسودان → الخرطوم • قيد النقل'), findsOneWidget);
    expect(find.textContaining('ناقل تجريبي'), findsOneWidget);
    expect(find.textContaining('تغليف, توقيع المستلم'), findsOneWidget);
    expect(find.textContaining('ملاحظات: اتصل قبل الوصول'), findsOneWidget);
  });

  testWidgets('cargo drafts survive reopening the transport screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenTransportScreen()));
    await openSection(tester, 'Freight & Cargo Coordination');

    await enterField(tester, 'مرجع الشحنة', 'PERSIST-2026');
    await enterField(tester, 'من', 'بورتسودان');
    await enterField(tester, 'إلى', 'عطبرة');
    await enterField(tester, 'الناقل (اختياري)', 'ناقل محفوظ');
    await tester.ensureVisible(find.text('حفظ مسودة الشحنة'));
    await tester.tap(find.text('حفظ مسودة الشحنة'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: AurenTransportScreen()));
    await tester.pumpAndSettle();
    await openSection(tester, 'Freight & Cargo Coordination');

    expect(find.textContaining('PERSIST-2026: بورتسودان → عطبرة'), findsOneWidget);
    expect(find.textContaining('ناقل محفوظ'), findsOneWidget);
  });

  testWidgets('saved cargo shipment status updates persist locally', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenTransportScreen()));
    await openSection(tester, 'Freight & Cargo Coordination');

    await enterField(tester, 'مرجع الشحنة', 'STATUS-101');
    await enterField(tester, 'من', 'بورتسودان');
    await enterField(tester, 'إلى', 'الخرطوم');
    await tester.ensureVisible(find.text('حفظ مسودة الشحنة'));
    await tester.tap(find.text('حفظ مسودة الشحنة'));
    await tester.pumpAndSettle();

    final statusDropdown = find.byKey(const ValueKey('cargo-status-0'));
    await tester.ensureVisible(statusDropdown);
    await tester.tap(statusDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تم التسليم').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('STATUS-101: بورتسودان → الخرطوم • تم التسليم'), findsOneWidget);
    expect(find.text('تم تحديث حالة الشحنة وحفظها محليًا.'), findsOneWidget);

    final stored = await MobilityLocalStore().loadShipments();
    expect(stored, hasLength(1));
    expect(stored.single.status, CargoStatus.delivered);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: AurenTransportScreen()));
    await tester.pumpAndSettle();
    await openSection(tester, 'Freight & Cargo Coordination');

    expect(find.textContaining('STATUS-101: بورتسودان → الخرطوم • تم التسليم'), findsOneWidget);
  });

  testWidgets('vehicle records surface insurance and maintenance alerts', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenTransportScreen()));
    await openSection(tester, 'Vehicle Ownership');

    final today = DateTime.now();
    final soon = today.add(const Duration(days: 1));
    final overdue = today.subtract(const Duration(days: 1));
    String date(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

    await enterField(tester, 'الشركة / الصانع', 'Toyota');
    await enterField(tester, 'الطراز', 'Corolla');
    await enterField(tester, 'سنة الصنع', '2020');
    await enterField(tester, 'ملاحظات المركبة (اختياري)', 'تغيير زيت قريب');
    await enterField(
      tester,
      'انتهاء التأمين YYYY-MM-DD (اختياري)',
      date(soon),
    );
    await enterField(
      tester,
      'موعد الصيانة YYYY-MM-DD (اختياري)',
      date(overdue),
    );

    await tester.ensureVisible(find.text('إضافة مركبة'));
    await tester.tap(find.text('إضافة مركبة'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ملاحظات: تغيير زيت قريب'), findsOneWidget);
    expect(find.textContaining('تنبيه: التأمين يحتاج مراجعة'), findsOneWidget);
    expect(find.textContaining('تنبيه: موعد الصيانة حان أو فات'), findsOneWidget);
  });
}
