import 'package:auren/features/global_directory/presentation/auren_supplier_discovery_screen.dart';
import 'package:auren/features/global_directory/presentation/auren_supplier_rfq_draft_screen.dart';
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
    final budgetField = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'الميزانية القصوى (اختياري)');
    await tester.enterText(productField, 'ألواح شمسية');
    await tester.enterText(quantityField, '20 لوحة');
    await tester.enterText(destinationField, 'بورتسودان، السودان');
    await tester.enterText(budgetField, '2500');
    await tester.pumpAndSettle();

    await tester.tap(find.text('عملة الميزانية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SDG').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('جهّز طلب عرض سعر لاحتياجي'));
    await tester.pumpAndSettle();

    expect(find.text('طلب عرض سعر من مورد'), findsOneWidget);
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(fields[0].controller?.text, isEmpty);
    expect(fields[1].controller?.text, 'ألواح شمسية');
    expect(fields[2].controller?.text, '20 لوحة');
    expect(fields[3].controller?.text, 'بورتسودان، السودان');
    expect(fields[5].controller?.text, '2500');
    expect(find.text('SDG'), findsWidgets);
    expect(find.textContaining('لن يتم التواصل مع أي مورد تلقائياً'),
        findsOneWidget);
  });

  testWidgets('purchasing need carries into offer comparison as context',
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
    final budgetField = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'الميزانية القصوى (اختياري)');

    await tester.enterText(productField, 'ألواح شمسية');
    await tester.enterText(quantityField, '20 لوحة');
    await tester.enterText(destinationField, 'بورتسودان، السودان');
    await tester.enterText(budgetField, '2500');
    await tester.pumpAndSettle();

    await tester.tap(find.text('مقارنة عروض الأسعار المسجلة'));
    await tester.pumpAndSettle();

    expect(find.text('احتياجك للمقارنة'), findsOneWidget);
    expect(find.text('المنتج: ألواح شمسية'), findsOneWidget);
    expect(find.text('الكمية: 20 لوحة'), findsOneWidget);
    expect(find.text('وجهة التسليم: بورتسودان، السودان'), findsOneWidget);
    expect(find.text('الميزانية المطلوبة: 2500 USD'), findsOneWidget);
    expect(find.text('لا توجد عروض بعد. اضغط «إضافة عرض» لتسجيل أول عرض.'),
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

  testWidgets('RFQ draft rejects malformed grouped budget amounts', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: AurenSupplierRfqDraftScreen(
        auth: MockFirebaseAuth(),
        firestore: FakeFirebaseFirestore(),
      ),
    ));
    await tester.pumpAndSettle();

    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    await tester.enterText(find.byWidgetPredicate((widget) =>
      widget is TextFormField && widget.decoration?.labelText == 'المنتج أو الخدمة *'), 'قماش');
    await tester.enterText(find.byWidgetPredicate((widget) =>
      widget is TextFormField && widget.decoration?.labelText == 'الكمية المطلوبة *'), '500 قطعة');
    await tester.enterText(find.byWidgetPredicate((widget) =>
      widget is TextFormField && widget.decoration?.labelText == 'مدينة وبلد التسليم *'), 'الخرطوم، السودان');
    await tester.enterText(find.byWidgetPredicate((widget) =>
      widget is TextFormField && widget.decoration?.labelText == 'الميزانية (اختياري)'), '1,,200');
    await tester.tap(find.text('إنشاء مسودة طلب السعر'));
    await tester.pumpAndSettle();

    expect(find.text('أدخل ميزانية رقمية غير سالبة'), findsOneWidget);
    expect(find.text('راجع المسودة'), findsNothing);
  });

  testWidgets('RFQ cloud restore ignores a draft owned by another user',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'user-a'),
    );
    final firestore = FakeFirebaseFirestore();
    await firestore
        .collection('users')
        .doc('user-a')
        .collection('supplier_rfq_drafts')
        .doc('active_draft')
        .set({
      'ownerId': 'user-b',
      'target': 'Private supplier',
      'product': 'Private product',
      'quantity': '100',
      'destination': 'Khartoum, Sudan',
      'specifications': '',
      'budget': '50',
      'currency': 'USD',
      'delivery': 'شحن إلى العنوان',
      'contact': '',
      'draft': 'Private draft text',
    });

    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: AurenSupplierRfqDraftScreen(
        auth: auth,
        firestore: firestore,
      ),
    ));
    await tester.pumpAndSettle();

    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(fields[0].controller?.text, isEmpty);
    expect(fields[1].controller?.text, isEmpty);
    expect(find.text('Private draft text'), findsNothing);
  });
}
