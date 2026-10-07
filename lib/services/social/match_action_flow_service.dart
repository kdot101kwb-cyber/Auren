import 'package:cloud_firestore/cloud_firestore.dart';

import 'match_everything_service.dart';

class AurenMatchActionFlowState {
  final String flowId;
  final String status;
  final int step;
  final String intent;
  final String targetId;
  final String targetKind;
  final String? conversationId;
  final String? replyMessageId;
  final DateTime? replyDetectedAt;
  final DateTime? updatedAt;

  const AurenMatchActionFlowState({
    required this.flowId,
    required this.status,
    required this.step,
    required this.intent,
    required this.targetId,
    required this.targetKind,
    this.conversationId,
    this.replyMessageId,
    this.replyDetectedAt,
    this.updatedAt,
  });

  bool get completed => status == 'completed';

  factory AurenMatchActionFlowState.fromDoc(String id, Map<String, dynamic> data) {
    final raw = data['updatedAt'];
    final rawReplyDetectedAt = data['replyDetectedAt'];
    return AurenMatchActionFlowState(
      flowId: id,
      status: (data['status'] ?? 'active').toString(),
      step: (data['step'] as num?)?.toInt() ?? 0,
      intent: (data['intent'] ?? '').toString(),
      targetId: (data['targetId'] ?? '').toString(),
      targetKind: (data['targetKind'] ?? '').toString(),
      conversationId: (data['conversationId'] as String?)?.trim().isEmpty == true
          ? null
          : (data['conversationId'] as String?)?.trim(),
      replyMessageId: (data['replyMessageId'] as String?)?.trim().isEmpty == true
          ? null
          : (data['replyMessageId'] as String?)?.trim(),
      replyDetectedAt: rawReplyDetectedAt is Timestamp
          ? rawReplyDetectedAt.toDate()
          : null,
      updatedAt: raw is Timestamp ? raw.toDate() : null,
    );
  }
}

class AurenMatchActionFlowRepository {
  final FirebaseFirestore _db;

  AurenMatchActionFlowRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  String _flowId(AurenMatchItem item) {
    final raw = '${item.kind.name}_${item.id}'
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return raw.substring(0, raw.length > 120 ? 120 : raw.length);
  }

  DocumentReference<Map<String, dynamic>> _ref(
    String uid,
    AurenMatchItem item,
  ) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('match_action_flows')
          .doc(_flowId(item));

  Future<AurenMatchActionFlowState?> get(
    String uid,
    AurenMatchItem item,
  ) async {
    final snap = await _ref(uid, item).get();
    if (!snap.exists || snap.data() == null) return null;
    return AurenMatchActionFlowState.fromDoc(snap.id, snap.data()!);
  }

  Future<AurenMatchActionFlowState> startOrAdvance({
    required String uid,
    required AurenMatchItem item,
    required String intent,
    required int step,
    required int totalSteps,
    String? status,
    String? conversationId,
  }) async {
    if (totalSteps < 1) {
      throw ArgumentError('totalSteps must be at least 1');
    }
    final safeStep = step.clamp(0, totalSteps - 1).toInt();
    final cleanIntent = intent.trim();
    final ref = _ref(uid, item);

    await ref.set({
      'targetId': item.id,
      'targetKind': item.kind.name,
      'action': item.action.name,
      'intent': cleanIntent.length > 1000
          ? cleanIntent.substring(0, 1000)
          : cleanIntent,
      'step': safeStep,
      'status': status ??
          (safeStep >= totalSteps - 1 ? 'completed' : 'active'),
      'totalSteps': totalSteps,
      if (conversationId != null && conversationId.trim().isNotEmpty)
        'conversationId': conversationId.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final snap = await ref.get();
    return AurenMatchActionFlowState.fromDoc(snap.id, snap.data()!);
  }

  Future<void> updateStatus({
    required String uid,
    required AurenMatchItem item,
    required String status,
  }) async {
    const allowed = {
      'active',
      'waiting_response',
      'replied',
      'completed',
      'failed',
      'cancelled',
    };
    if (!allowed.contains(status)) {
      throw ArgumentError('Invalid flow status');
    }
    await _ref(uid, item).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> retry({
    required String uid,
    required AurenMatchItem item,
  }) async {
    final ref = _ref(uid, item);
    await ref.update({
      'status': 'active',
      'lastError': FieldValue.delete(),
      'cancelledAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> fail({
    required String uid,
    required AurenMatchItem item,
    String? reason,
  }) async {
    await _ref(uid, item).update({
      'status': 'failed',
      if (reason != null && reason.trim().isNotEmpty) 'lastError': reason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancel({
    required String uid,
    required AurenMatchItem item,
  }) async {
    await _ref(uid, item).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markReplied({
    required String uid,
    required AurenMatchItem item,
  }) =>
      updateStatus(uid: uid, item: item, status: 'replied');

  /// Completes the flow and moves the progress indicator to its final step.
  Future<void> complete({
    required String uid,
    required AurenMatchItem item,
  }) async {
    final ref = _ref(uid, item);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw StateError('Match Everything flow not found.');
      }
      final data = snap.data() ?? <String, dynamic>{};
      final totalSteps = (data['totalSteps'] as num?)?.toInt() ?? 1;
      final finalStep = totalSteps > 0 ? totalSteps - 1 : 0;
      tx.update(ref, {
        'status': 'completed',
        'step': finalStep,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
