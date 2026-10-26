import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/security/password_lab_screen.dart';

void main() {
  testWidgets('Password Lab exposes recovery, Wi-Fi guidance and authorized website check', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PasswordLabScreen()));

    expect(find.text('NOVA Password Lab'), findsOneWidget);
    expect(find.text('استرداد الحسابات'), findsOneWidget);
    expect(find.text('فحص أمان Wi-Fi'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('فحص أمان موقع مصرح به'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('فحص أمان موقع مصرح به'), findsOneWidget);
    expect(find.text('أملك هذا الموقع أو لدي إذن صريح لفحصه.'), findsOneWidget);
    expect(find.text('فحص الترويسات'), findsOneWidget);
  });

  testWidgets('website check requires explicit authorization', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PasswordLabScreen()));
    await tester.scrollUntilVisible(find.byType(TextField), 300, scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byType(TextField), 'https://example.com');
    await tester.tap(find.text('فحص الترويسات'));
    await tester.pumpAndSettle();

    expect(find.text('أكد أولاً أنك تملك الموقع أو لديك إذن صريح لفحصه.'), findsOneWidget);
  });
}
