import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auren/features/everyday_life/presentation/household_inventory_screen.dart';
import 'package:auren/services/auth/auth_service.dart';
import 'package:auren/services/everyday/household_inventory_service.dart';
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

  Future<void> settleAfterDialog(WidgetTester tester) async {
    await tester.pumpAndSettle();
    // The screen keeps text controllers alive until the real dialog-dismissal
    // delay completes; let that timer run outside the fake-async test zone.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 550)),
    );
    await tester.pumpAndSettle();
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

    final itemNameField = find.byType(TextFormField).first;
    await tester.enterText(itemNameField, 'رز');
    await tester.tap(find.text('حفظ'));
    await settleAfterDialog(tester);

    expect(find.text('رز'), findsOneWidget);
    expect(find.textContaining('1.0 قطعة'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'إضافة'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة كمية'), findsOneWidget);

    await tester.tap(find.text('تأكيد'));
    await settleAfterDialog(tester);

    expect(find.textContaining('2.0 قطعة'), findsOneWidget);
    expect(find.text('سجل الحركة (1)'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'استهلاك'));
    await tester.pumpAndSettle();
    expect(find.text('تسجيل استهلاك'), findsOneWidget);

    await tester.tap(find.text('تأكيد'));
    await settleAfterDialog(tester);

    expect(find.textContaining('1.0 قطعة'), findsOneWidget);
    expect(find.text('سجل الحركة (2)'), findsOneWidget);

    await tester.tap(find.text('سجل الحركة (2)'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة: 1.0 قطعة'), findsOneWidget);
    expect(find.text('استهلاك: 1.0 قطعة'), findsOneWidget);
  });
  testWidgets('filters low stock and editing metadata preserves quantity',
      (tester) async {
    final store = AurenHouseholdInventoryStore();
    await store.saveItem(
      'inventory-test-user',
      AurenHouseholdItem(
        id: 'rice',
        name: 'رز',
        category: 'مطبخ',
        quantity: 0.5,
        lowStockThreshold: 1,
        unit: 'كجم',
      ),
    );
    await store.saveItem(
      'inventory-test-user',
      AurenHouseholdItem(
        id: 'soap',
        name: 'صابون',
        category: 'تنظيف',
        quantity: 4,
        lowStockThreshold: 1,
        unit: 'قطعة',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AurenHouseholdInventoryScreen(
          authService: _FakeAuthService('inventory-test-user'),
          store: store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('رز'), findsOneWidget);
    expect(find.text('صابون'), findsOneWidget);

    await tester.tap(find.text('عرض العناصر التي وصلت لحد التنبيه فقط'));
    await tester.pumpAndSettle();

    expect(find.text('رز'), findsOneWidget);
    expect(find.text('صابون'), findsNothing);

    await tester.tap(find.byTooltip('تحديث'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('تعديل'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(6));
    await tester.enterText(fields.at(1), 'مطبخ البيت');
    await tester.tap(find.text('حفظ'));
    await settleAfterDialog(tester);

    final saved = await store.loadItems('inventory-test-user');
    final rice = saved.singleWhere((item) => item.id == 'rice');
    expect(rice.category, 'مطبخ البيت');
    expect(rice.quantity, 0.5);
    expect(saved.singleWhere((item) => item.id == 'soap').quantity, 4);
  });

  testWidgets('shows a recoverable error for malformed local data without overwriting it',
      (tester) async {
    const storageKey = 'auren_household_inventory_v1_dXNlci1B';
    const corruptedValue = '{not valid JSON';
    SharedPreferences.setMockInitialValues({
      storageKey: corruptedValue,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AurenHouseholdInventoryScreen(
          authService: _FakeAuthService('user-A'),
          store: AurenHouseholdInventoryStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('تعذّر تحميل المخزون. لم يتم تعديل البيانات المحفوظة؛ حاول مرة أخرى.'),
      findsOneWidget,
    );
    expect(find.textContaining('FormatException'), findsNothing);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(storageKey), corruptedValue);
    expect(find.text('لسه ما أضفت أي عنصر'), findsNothing);
  });

}
