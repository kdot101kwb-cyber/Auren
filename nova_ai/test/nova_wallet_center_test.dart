import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/features/finance/nova_wallet_center_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows Bravo and MyCashi with explicit local-only status',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NovaWalletCenterScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('محافظ NOVA المالية'), findsOneWidget);
    expect(find.text('برافو'), findsOneWidget);
    expect(find.text('ماي كاشي'), findsOneWidget);
    expect(find.textContaining('لا يوجد ربط مباشر بالحسابات'), findsOneWidget);
    expect(find.text('تسجيل حركة'), findsOneWidget);
  });

  testWidgets('entry form warns against storing wallet credentials',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NovaWalletCenterScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل حركة'));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل حركة مالية'), findsOneWidget);
    expect(find.textContaining('لا تدخل كلمة مرور أو رمز تحقق أو رقم بطاقة'),
        findsOneWidget);
    expect(find.text('دخل مستلم'), findsOneWidget);
    expect(find.text('مصروف'), findsOneWidget);
  });
}
