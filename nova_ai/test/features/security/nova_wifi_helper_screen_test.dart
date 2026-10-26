import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/security/nova_wifi_helper_screen.dart';

void main() {
  testWidgets('shows safe Wi-Fi help and settings action', (tester) async {
    await tester.pumpWidget(
      const TestApp(child: NovaWifiHelperScreen()),
    );
    expect(find.text('مساعد Wi-Fi في NOVA'), findsOneWidget);
    expect(find.text('فتح إعدادات Wi-Fi'), findsOneWidget);
    expect(find.textContaining('لا يكسر NOVA كلمات المرور'), findsOneWidget);
  });
}

class TestApp extends StatelessWidget {
  const TestApp({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(home: child);
}
