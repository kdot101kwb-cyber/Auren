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

  testWidgets('asks the user to sign in when no authenticated UID exists',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AurenHouseholdInventoryScreen(
          authService: _FakeAuthService(null),
          store: AurenHouseholdInventoryStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('سجّل الدخول أولاً لعرض مخزونك.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('shows the empty inventory state for an authenticated user',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AurenHouseholdInventoryScreen(
          authService: _FakeAuthService('inventory-test-user'),
          store: AurenHouseholdInventoryStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مخزون المنزل'), findsOneWidget);
    expect(find.text('لسه ما أضفت أي عنصر'), findsOneWidget);
    expect(find.text('أضف أول عنصر'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });
}
