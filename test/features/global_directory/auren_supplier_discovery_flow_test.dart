import 'package:auren/features/global_directory/presentation/auren_supplier_discovery_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpDiscovery(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: AurenSupplierDiscoveryScreen(
        auth: MockFirebaseAuth(),
        firestore: FakeFirebaseFirestore(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('supplier discovery links to the offer comparison screen',
      (tester) async {
    await pumpDiscovery(tester);

    await tester.tap(find.text('مقارنة عروض الأسعار المسجلة'));
    await tester.pumpAndSettle();

    expect(find.text('مقارنة عروض الموردين'), findsOneWidget);
    expect(find.text('لا توجد عروض بعد. اضغط «إضافة عرض» لتسجيل أول عرض.'),
        findsOneWidget);
  });

  testWidgets('discovery can prepare an editable RFQ draft for a listed source',
      (tester) async {
    await pumpDiscovery(tester);

    await tester.tap(find.text('جهّز طلب عرض سعر').first);
    await tester.pumpAndSettle();

    expect(find.text('طلب عرض سعر من مورد'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).controller?.text,
      'Alibaba.com',
    );
    expect(find.textContaining('لن يتم التواصل مع أي مورد تلقائياً'),
        findsOneWidget);
  });

  testWidgets('a product need opens a prefilled RFQ draft without a supplier',
      (tester) async {
    await pumpDiscovery(tester);

    final productField = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'مثال: ألواح شمسية أو بذور قمح');
    final quantityField = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'الكمية المطلوبة (اختياري)');
    final destinationField = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'مدينة وبلد التسليم (اختياري)');
    await tester.enterText(productField, 'ألواح شمسية');
    await tester.enterText(quantityField, '20 لوحة');
    await tester.enterText(destinationField, 'بورتسودان، السودان');
    await tester.pumpAndSettle();

    await tester.tap(find.text('جهّز طلب عرض سعر لاحتياجي'));
    await tester.pumpAndSettle();

    expect(find.text('طلب عرض سعر من مورد'), findsOneWidget);
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(fields[0].controller?.text, isEmpty);
    expect(fields[1].controller?.text, 'ألواح شمسية');
    expect(fields[2].controller?.text, '20 لوحة');
    expect(fields[3].controller?.text, 'بورتسودان، السودان');
    expect(find.textContaining('لن يتم التواصل مع أي مورد تلقائياً'),
        findsOneWidget);
  });

  testWidgets('supplier source search filters the listed platforms',
      (tester) async {
    await pumpDiscovery(tester);

    final sourceSearch = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'ابحث عن قطاع أو منصة أو نوع مورد');
    await tester.enterText(sourceSearch, 'Thomasnet');
    await tester.pumpAndSettle();

    expect(find.text('Thomasnet'), findsAtLeastNWidgets(1));
    expect(find.text('Alibaba.com'), findsNothing);
  });
}
