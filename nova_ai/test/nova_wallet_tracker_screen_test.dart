import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/features/wallets/nova_wallet_tracker_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows Bravo and MyCashi with manual-only safety copy', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaWalletTrackerScreen()));
    await tester.pumpAndSettle();

    expect(find.text('محافظ NOVA'), findsOneWidget);
    expect(find.text('Bravo'), findsOneWidget);
    expect(find.text('MyCashi'), findsNothing); // Available from the provider selector.
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();
    expect(find.text('MyCashi').last, findsOneWidget);
    expect(find.textContaining('ليست رصيداً حياً مؤكداً'), findsOneWidget);
  });

  testWidgets('saves a manual income entry locally and displays it', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaWalletTrackerScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'المبلغ'), '125.50');
    await tester.enterText(find.widgetWithText(TextFormField, 'ملاحظة (اختياري)'), 'اختبار دخل');
    await tester.ensureVisible(find.text('حفظ السجل على الهاتف'));
    await tester.tap(find.text('حفظ السجل على الهاتف'));
    await tester.pumpAndSettle();

    expect(find.textContaining('اختبار دخل'), findsOneWidget);
    expect(find.textContaining('125.50 SDG'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('nova.wallet.tracker.entries.v1'), contains('اختبار دخل'));
  });
}
