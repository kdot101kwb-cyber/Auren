import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/features/everyday_life/presentation/everyday_services_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('requires a signed-in user before showing personal service data', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AurenEverydayServicesScreen(useUidOverride: true, uidOverride: null),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('سجّل الدخول'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('shows four service areas and opens the maintenance area', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AurenEverydayServicesScreen(useUidOverride: true, uidOverride: 'everyday-widget-test'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Everyday Life & Services'), findsOneWidget);
    expect(find.text('المواعيد'), findsOneWidget);
    expect(find.text('الصيانة'), findsOneWidget);
    expect(find.text('الرحلات'), findsOneWidget);
    expect(find.text('العدادات'), findsOneWidget);
    expect(find.text('مسودات المواعيد'), findsOneWidget);

    await tester.tap(find.text('الصيانة'));
    await tester.pumpAndSettle();
    expect(find.text('صيانة المنزل'), findsOneWidget);
    expect(find.textContaining('لا يتم طلب خدمة'), findsOneWidget);
  });
}
