import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/core/approval/nova_owner_action_queue.dart';
import 'package:nova_ai/features/approvals/nova_approval_center_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('approval center records explicit owner approval without execution', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = NovaOwnerActionQueue(preferences: prefs);
    await queue.enqueue(
      id: 'publish-1',
      actionType: 'social_publish',
      summary: 'نشر منشور تجريبي',
      isReadOnly: false,
      externalSideEffect: true,
    );

    await tester.pumpWidget(MaterialApp(home: NovaApprovalCenterScreen(queue: queue)));
    await tester.pumpAndSettle();
    expect(find.text('بانتظار موافقتك'), findsOneWidget);
    await tester.tap(find.text('موافقة صريحة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أوافق'));
    await tester.pumpAndSettle();

    final records = await queue.list();
    expect(records.single.status, NovaActionStatus.approved);
    expect(find.text('موافق عليه'), findsOneWidget);
  });
}
