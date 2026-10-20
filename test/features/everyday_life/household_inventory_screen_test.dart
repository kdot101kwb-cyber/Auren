import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auren/features/everyday_life/presentation/household_inventory_screen.dart';
import 'package:auren/services/auth/auth_service.dart';
import 'package:auren/services/everyday/household_inventory_store.dart';

class _FakeAuthService implements AurenAuthService {
  _FakeAuthService(this.currentUserId);

  @override
  final String? currentUserId;

  @override
  Stream<String?> get authStateChanges => Stream.value(currentUserId);

  @override
  Future<String> signInAnonymously() async => currentUserId ?? 'test-user';

  @override
  Future<void> signOut() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildScreen({String? uid = 'inventory-test-user'}) {
    return MaterialApp(
      home: AurenHouseholdInventoryScreen(
        authService: _FakeAuthService(uid),
        store: AurenHouseholdInventoryStore(),
      ),
    );
  }

  testWidgets('asks the user to sign in when no authenticated UID exists',
      (tester) async {
    await tester.pumpWidget(buildScreen(uid: null));
    await tester.pumpAndSettle();

    expect(find.text('سجّل الدخول أولاً لعرض مخزونك.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('shows the empty inventory state for an authenticated user',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('مخزون المنزل'), findsOneWidget);
    expect(find.text('لسه ما أضفت أي عنصر'), findsOneWidget);
    expect(find.text('أضف أول عنصر'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('creates an item and records restock and consumption movements',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('أضف أول عنصر'));
    await tester.pumpAndSettle();

    final itemNameField = find.byWidgetPredicate(
      (widget) =>
          widget is TextFormField &&
          widget.decoration?.labelText == 'اسم العنصر',
    );
    await tester.enterText(itemNameField, 'رز');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(find.text('رز'), findsOneWidget);
    expect(find.textContaining('1.0 قطعة'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'إضافة'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة كمية'), findsOneWidget);

    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    expect(find.textContaining('2.0 قطعة'), findsOneWidget);
    expect(find.text('سجل الحركة (1)'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'استهلاك'));
    await tester.pumpAndSettle();
    expect(find.text('تسجيل استهلاك'), findsOneWidget);

    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1.0 قطعة'), findsOneWidget);
    expect(find.text('سجل الحركة (2)'), findsOneWidget);

    await tester.tap(find.text('سجل الحركة (2)'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة: 1.0 قطعة'), findsOneWidget);
    expect(find.text('استهلاك: 1.0 قطعة'), findsOneWidget);
  });
}
