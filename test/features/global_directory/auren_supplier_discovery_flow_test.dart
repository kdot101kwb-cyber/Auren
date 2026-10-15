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

  testWidgets('discovery exposes the supplier requests workflow',
      (tester) async {
    await pumpDiscovery(tester);

    expect(find.text('طلبات الموردين'), findsOneWidget);
    expect(
      find.textContaining('تابع مسودات طلباتك وحالاتها'),
      findsOneWidget,
    );
  });

  testWidgets('supplier source search filters the listed platforms',
      (tester) async {
    await pumpDiscovery(tester);

    await tester.enterText(find.byType(TextField).first, 'Thomasnet');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Thomasnet'), findsOneWidget);
    expect(find.text('Alibaba.com'), findsNothing);
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
