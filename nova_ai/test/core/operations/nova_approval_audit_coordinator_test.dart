import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/core/approval/nova_owner_action_queue.dart';
import 'package:nova_ai/core/audit/nova_local_audit_ledger.dart';
import 'package:nova_ai/core/operations/nova_approval_audit_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('owner approval is recorded in the local audit timeline', () async {
    final queue = NovaOwnerActionQueue();
    final ledger = NovaLocalAuditLedger();
    final coordinator = NovaApprovalAuditCoordinator(
      queue: queue,
      ledger: ledger,
    );

    expect(
      await queue.enqueue(
        id: 'approval-approve-1',
        actionType: 'publish_post',
        summary: 'Publish the reviewed campaign',
        isReadOnly: false,
        externalSideEffect: true,
        sensitive: true,
      ),
      isTrue,
    );

    expect(
      await coordinator.approve('approval-approve-1', ownerConfirmed: true),
      isTrue,
    );
    expect(
      (await queue.list()).single.status,
      NovaActionStatus.approved,
    );

    final events = await ledger.read();
    expect(events, hasLength(1));
    expect(events.single.type, 'owner_approval');
    expect(events.single.actionId, 'approval-approve-1');
    expect(events.single.metadata['decision'], 'approved');
  });

  test('owner rejection and reason are recorded in the local audit timeline', () async {
    final queue = NovaOwnerActionQueue();
    final ledger = NovaLocalAuditLedger();
    final coordinator = NovaApprovalAuditCoordinator(
      queue: queue,
      ledger: ledger,
    );

    await queue.enqueue(
      id: 'approval-reject-1',
      actionType: 'transfer_funds',
      summary: 'Transfer requested funds',
      isReadOnly: false,
      externalSideEffect: true,
      sensitive: true,
    );

    expect(
      await coordinator.reject('approval-reject-1', reason: 'Not authorized'),
      isTrue,
    );
    expect(
      (await queue.list()).single.status,
      NovaActionStatus.rejected,
    );

    final events = await ledger.read();
    expect(events, hasLength(1));
    expect(events.single.type, 'owner_rejection');
    expect(events.single.metadata['decision'], 'rejected');
    expect(events.single.metadata['reason'], 'Not authorized');
  });

  test('approval without explicit owner confirmation is not recorded', () async {
    final queue = NovaOwnerActionQueue();
    final ledger = NovaLocalAuditLedger();
    final coordinator = NovaApprovalAuditCoordinator(
      queue: queue,
      ledger: ledger,
    );

    await queue.enqueue(
      id: 'approval-no-confirm',
      actionType: 'external_action',
      summary: 'A sensitive action',
      isReadOnly: false,
      externalSideEffect: true,
      sensitive: true,
    );

    expect(
      await coordinator.approve('approval-no-confirm', ownerConfirmed: false),
      isFalse,
    );
    expect((await queue.list()).single.status, NovaActionStatus.awaitingApproval);
    expect(await ledger.read(), isEmpty);
  });
}
