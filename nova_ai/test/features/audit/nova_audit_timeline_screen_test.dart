import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/core/audit/nova_local_audit_ledger.dart';
import 'package:nova_ai/features/audit/nova_audit_timeline_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('audit timeline displays events with redacted metadata', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ledger = NovaLocalAuditLedger(preferences: prefs);
    await ledger.append(
      id: 'event-1',
      type: 'approval',
      message: 'تم تسجيل قرار المالك',
      metadata: {'api_key': 'synthetic-secret-value', 'source': 'test'},
    );

    await tester.pumpWidget(MaterialApp(home: NovaAuditTimelineScreen(ledger: ledger)));
    await tester.pumpAndSettle();
    expect(find.text('تم تسجيل قرار المالك'), findsOneWidget);
    await tester.tap(find.text('تم تسجيل قرار المالك'));
    await tester.pumpAndSettle();

    expect(find.textContaining('[redacted]'), findsOneWidget);
    expect(find.textContaining('synthetic-secret-value'), findsNothing);
  });
}
