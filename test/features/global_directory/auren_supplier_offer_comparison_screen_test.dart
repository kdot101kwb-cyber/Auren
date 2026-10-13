import 'dart:convert';

import 'package:auren/features/global_directory/presentation/auren_supplier_offer_comparison_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, String> offer(
  String id,
  String name,
  String price,
  String currency, {
  String status = 'received',
  String validity = '',
  String shipping = '0',
}) =>
    {
      'id': id,
      'supplier': name,
      'price': price,
      'currency': currency,
      'shipping': shipping,
      'moq': '',
      'leadTime': '',
      'payment': '',
      'validity': validity,
      'notes': '',
      'status': status,
      'receivedAt': '2026-10-01T00:00:00.000',
    };

Future<void> pumpScreen(
  WidgetTester tester, {
  required List<Map<String, String>> localOffers,
  MockFirebaseAuth? auth,
  FakeFirebaseFirestore? firestore,
  String? initialProduct,
  String? initialQuantity,
  String? initialDestination,
  String? initialBudget,
  String? initialCurrency,
}) async {
  SharedPreferences.setMockInitialValues({
    'auren_supplier_offers_v1_guest': jsonEncode(localOffers),
  });
  await tester.binding.setSurfaceSize(const Size(800, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: AurenSupplierOfferComparisonScreen(
      auth: auth ?? MockFirebaseAuth(),
      firestore: firestore ?? FakeFirebaseFirestore(),
      initialProduct: initialProduct,
      initialQuantity: initialQuantity,
      initialDestination: initialDestination,
      initialBudget: initialBudget,
      initialCurrency: initialCurrency,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('request quantity pre-fills the maximum supplier MOQ constraint',
      (tester) async {
    await pumpScreen(
      tester,
      localOffers: [
        offer('1', 'MOQ 10 Supplier', '100', 'USD'),
        offer('2', 'MOQ 30 Supplier', '80', 'USD'),
      ],
      initialProduct: 'Solar panels',
      initialQuantity: '20 panels',
      initialDestination: 'Port Sudan, Sudan',
      initialBudget: '2500',
      initialCurrency: 'USD',
    );

    expect(find.text('احتياجك للمقارنة'), findsOneWidget);
    expect(find.text('المنتج: Solar panels'), findsOneWidget);
    expect(find.text('الكمية: 20 panels'), findsOneWidget);
    expect(find.text('وجهة التسليم: Port Sudan, Sudan'), findsOneWidget);
    expect(find.text('الميزانية المطلوبة: 2500 USD'), findsOneWidget);
    expect(find.text('كمية طلبك / أقصى حد أدنى للطلب'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller?.text,
      '20 panels',
    );
    expect(find.text('MOQ 10 Supplier'), findsNWidgets(2));
    expect(find.text('MOQ 30 Supplier'), findsNWidgets(2));
  });

  testWidgets('unparseable requested quantity is not silently applied',
      (tester) async {
    await pumpScreen(
      tester,
      localOffers: [offer('1', 'Supplier A', '100', 'USD')],
      initialQuantity: 'about twenty panels',
    );

    expect(
      find.textContaining('تعذر قراءة كمية الطلب كرقم'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller?.text,
      isEmpty,
    );
  });

  testWidgets('blank freight stays incomplete in the comparison', (tester) async {
    await pumpScreen(tester, localOffers: [
      offer('1', 'Supplier Without Freight Quote', '100', 'USD', shipping: ''),
      offer('2', 'Supplier With Freight Quote', '125', 'USD', shipping: '10'),
    ]);
    expect(find.text('غير معروف — لم يُدخل'), findsOneWidget);
    expect(find.text('الإجمالي غير مكتمل — أدخل الشحن والرسوم أولاً'), findsOneWidget);
    expect(find.text('الإجمالي التقديري: 135.00 USD'), findsOneWidget);
  });

  testWidgets('new quote form leaves unprovided shipping blank', (tester) async {
    await pumpScreen(tester, localOffers: []);
    await tester.tap(find.text('إضافة عرض'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Freight Pending Supplier');
    await tester.enterText(fields.at(1), '100');
    expect(tester.widget<TextFormField>(fields.at(2)).controller?.text, isEmpty);
    await tester.tap(find.text('حفظ العرض'));
    await tester.pumpAndSettle();
    expect(find.text('غير معروف — لم يُدخل'), findsOneWidget);
    expect(find.text('الإجمالي غير مكتمل — أدخل الشحن والرسوم أولاً'), findsOneWidget);
  });

  testWidgets('rejected offers are excluded from ranking', (tester) async {
    await pumpScreen(tester, localOffers: [
      offer('1', 'Supplier A', '100', 'USD', status: 'rejected'),
      offer('2', 'Supplier B', '120', 'USD'),
    ]);
    expect(find.text('Supplier B'), findsNWidgets(2));
    expect(find.text('Supplier A'), findsOneWidget);
  });

  testWidgets('expired offers are excluded from ranking', (tester) async {
    await pumpScreen(tester, localOffers: [
      offer('1', 'Expired Supplier', '50', 'USD', validity: '2026-10-01'),
      offer('2', 'Current Supplier', '70', 'USD'),
    ]);
    expect(find.text('Current Supplier'), findsNWidgets(2));
    expect(find.text('Expired Supplier'), findsOneWidget);
  });

  testWidgets('all rejected or expired offers show an explanatory message',
      (tester) async {
    await pumpScreen(tester, localOffers: [
      offer('1', 'Rejected Supplier', '50', 'USD', status: 'rejected'),
      offer('2', 'Expired Supplier', '70', 'EUR', validity: '2026-10-01'),
    ]);
    expect(find.text('كل العروض مرفوضة أو منتهية.'), findsOneWidget);
  });

  testWidgets('does not mix currencies in the ranking card', (tester) async {
    await pumpScreen(tester, localOffers: [
      offer('1', 'Dollar Co', '100', 'USD'),
      offer('2', 'Dirham Co', '90', 'AED'),
    ]);
    expect(find.text('Dirham Co'), findsNWidgets(2));
    expect(find.text('Dollar Co'), findsOneWidget);
  });

  testWidgets('budget remains tied to the currency in which it was entered',
      (tester) async {
    await pumpScreen(tester, localOffers: [
      offer('1', 'Dollar Co', '100', 'USD'),
      offer('2', 'Dirham Co', '90', 'AED'),
    ]);
    await tester.enterText(find.byType(TextField).first, '50');
    await tester.pumpAndSettle();

    // The ranking currency is the third dropdown after status and validity.
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('ولا تُطبَّق على USD'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).first).controller?.text, '50');
  });

  testWidgets('status filter hides non-matching offers', (tester) async {
    await pumpScreen(tester, localOffers: [
      offer('1', 'Alpha', '10', 'USD', status: 'shortlist'),
      offer('2', 'Beta', '20', 'USD'),
    ]);
    await tester.tap(find.text('كل العروض'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ضمن القائمة المختصرة').last);
    await tester.pumpAndSettle();
    expect(find.text('عرض 1 من 2 عروض'), findsOneWidget);
  });

  testWidgets('provisional selection opens an editable RFQ draft for that supplier',
      (tester) async {
    await pumpScreen(tester, localOffers: [
      offer('1', 'Selected Supplier', '100', 'USD'),
    ]);

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('اختير مبدئياً').last);
    await tester.pumpAndSettle();

    expect(find.text('إنشاء مسودة طلب سعر لهذا المورد'), findsOneWidget);
    await tester.tap(find.text('إنشاء مسودة طلب سعر لهذا المورد'));
    await tester.pumpAndSettle();

    expect(find.text('طلب عرض سعر من مورد'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).controller?.text,
      'Selected Supplier',
    );
    expect(
      find.textContaining('لن يتم التواصل مع أي مورد تلقائياً'),
      findsOneWidget,
    );
  });

  testWidgets('signed-in account reads its own local preference key',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'auren_supplier_offers_v1_guest':
          jsonEncode([offer('guest', 'Guest Supplier', '10', 'USD')]),
      'auren_supplier_offers_v1_u1':
          jsonEncode([offer('u1', 'Account Supplier', '20', 'USD')]),
    });
    await tester.binding.setSurfaceSize(const Size(800, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: AurenSupplierOfferComparisonScreen(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'u1'),
        ),
        firestore: FakeFirebaseFirestore(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Account Supplier'), findsNWidgets(2));
    expect(find.text('Guest Supplier'), findsNothing);
  });

  testWidgets('invalid price is rejected in the add-offer dialog',
      (tester) async {
    await pumpScreen(tester, localOffers: []);
    await tester.tap(find.text('إضافة عرض'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Test Supplier');
    await tester.enterText(find.byType(TextFormField).at(1), 'not-a-price');
    await tester.tap(find.text('حفظ العرض'));
    await tester.pumpAndSettle();

    expect(find.text('أدخل رقماً صحيحاً مثل 1200 أو 1,200.50'),
        findsOneWidget);
    expect(find.text('تسجيل عرض مورد'), findsOneWidget);
  });

  testWidgets('account restore asks before replacing local offers',
      (tester) async {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1'),
    );
    final firestore = FakeFirebaseFirestore();
    await firestore
        .collection('users')
        .doc('u1')
        .collection('supplier_offer_comparisons')
        .doc('active_draft')
        .set({
      'ownerId': 'u1',
      'offers': [offer('cloud', 'Cloud Supplier', '30', 'USD')],
    });

    SharedPreferences.setMockInitialValues({
      'auren_supplier_offers_v1_u1':
          jsonEncode([offer('local', 'Local Supplier', '40', 'USD')]),
    });
    await tester.binding.setSurfaceSize(const Size(800, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: AurenSupplierOfferComparisonScreen(
        auth: auth,
        firestore: firestore,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Local Supplier'), findsNWidgets(2));
    await tester.tap(find.text('استعادة من حسابي'));
    await tester.pumpAndSettle();
    expect(find.text('تأكيد استعادة العروض'), findsOneWidget);
    expect(
      find.text(
        'سيستبدل هذا عروضك المحلية الحالية بالعروض المحفوظة في الحساب. هل تريد المتابعة؟',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('استعادة').last);
    await tester.pumpAndSettle();
    expect(find.text('Cloud Supplier'), findsNWidgets(2));
    expect(find.text('Local Supplier'), findsNothing);
  });
}
