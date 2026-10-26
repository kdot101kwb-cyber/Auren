import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/security/presentation/nova_wifi_helper_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('nova/wifi');

  testWidgets('shows Wi-Fi helper guidance and action', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaWifiHelperScreen()));

    expect(find.text('NOVA Wi-Fi Helper'), findsOneWidget);
    expect(find.text('Open Wi-Fi settings'), findsOneWidget);
    expect(find.text('Open networks'), findsOneWidget);
    expect(find.text('Network protection'), findsOneWidget);
  });

  testWidgets('button requests Android Wi-Fi settings', (tester) async {
    var called = false;
    channel.setMockMethodCallHandler((call) async {
      expect(call.method, 'openWifiSettings');
      called = true;
      return null;
    });
    addTearDown(() => channel.setMockMethodCallHandler(null));

    await tester.pumpWidget(const MaterialApp(home: NovaWifiHelperScreen()));
    await tester.tap(find.text('Open Wi-Fi settings'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
  });
}
