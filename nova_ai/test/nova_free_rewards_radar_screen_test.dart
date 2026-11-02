import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/rewards/nova_free_rewards_radar_screen.dart';

void main() {
  testWidgets('shows the free rewards radar and honest payout limitations',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NovaFreeRewardsRadarScreen()),
      ),
    );

    expect(find.text('NOVA — رادار المكافآت المجانية'), findsOneWidget);
    expect(find.text('Blum'), findsOneWidget);
    expect(find.text('Catizen'), findsOneWidget);
    expect(find.text('Major'), findsOneWidget);
    expect(find.text('CryptoTab'), findsOneWidget);
    expect(find.text('PlayNXC'), findsOneWidget);
    expect(find.text('HaloArena'), findsOneWidget);
    expect(find.text('المصدر الرسمي'), findsNWidgets(6));
    expect(find.textContaining('لا نعتبر أي منصة مصدر دخل'), findsOneWidget);
  });
}
