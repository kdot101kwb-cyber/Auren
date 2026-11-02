import '../approval/nova_owner_action_queue.dart';
import '../audit/nova_local_audit_ledger.dart';

/// Records owner approval decisions and mirrors them into the local audit
/// timeline. This coordinator records decisions only; it never executes work.
class NovaApprovalAuditCoordinator {
  NovaApprovalAuditCoordinator({
    NovaOwnerActionQueue? queue,
    NovaLocalAuditLedger? ledger,
  })  : _queue = queue ?? NovaOwnerActionQueue(),
        _ledger = ledger ?? NovaLocalAuditLedger();

  final NovaOwnerActionQueue _queue;
  final NovaLocalAuditLedger _ledger;

  Future<bool> approve(String id, {required bool ownerConfirmed}) async {
    if (!ownerConfirmed) return false;
    final request = (await _queue.list())
        .where((item) => item.id == id)
        .firstOrNull;
    if (request == null) return false;

    final changed = await _queue.approve(id, ownerConfirmed: true);
    if (!changed) return false;
    await _ledger.append(
      id: 'owner-approved-$id',
      type: 'owner_approval',
      message: 'Owner approved: ${request.actionType}',
      actionId: id,
      metadata: <String, Object?>{
        'decision': 'approved',
        'actionType': request.actionType,
        'requiresOwnerApproval': request.requiresOwnerApproval,
      },
    );
    return true;
  }

  Future<bool> reject(String id, {required String reason}) async {
    if (reason.trim().isEmpty) return false;
    final request = (await _queue.list())
        .where((item) => item.id == id)
        .firstOrNull;
    if (request == null) return false;

    final changed = await _queue.reject(id, reason: reason);
    if (!changed) return false;
    await _ledger.append(
      id: 'owner-rejected-$id',
      type: 'owner_rejection',
      message: 'Owner rejected: ${request.actionType}',
      actionId: id,
      metadata: <String, Object?>{
        'decision': 'rejected',
        'actionType': request.actionType,
        'reason': reason.trim(),
      },
    );
    return true;
  }
}
