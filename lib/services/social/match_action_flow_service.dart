import 'package:cloud_firestore/cloud_firestore.dart';

import 'match_everything_service.dart';

class AurenMatchActionFlowState {
  final String flowId;
  final String status;
  final int step;
  final String intent;
  final String targetId;
  final String targetKind;
  final DateTime? updatedAt;
  const AurenMatchActionFlowState({required this.flowId, required this.status, required this.step, required this.intent, required this.targetId, required this.targetKind, this.updatedAt});
  bool get completed => status == 'completed';
  factory AurenMatchActionFlowState.fromDoc(String id, Map<String, dynamic> data) {
    final raw = data['updatedAt'];
    return AurenMatchActionFlowState(
      flowId: id, status: (data['status'] ?? 'active').toString(),
      step: (data['step'] as num?)?.toInt() ?? 0,
      intent: (data['intent'] ?? '').toString(),
      targetId: (data['targetId'] ?? '').toString(),
      targetKind: (data['targetKind'] ?? '').toString(),
      updatedAt: raw is Timestamp ? raw.toDate() : null,
    );
  }
}

class AurenMatchActionFlowRepository {
  final FirebaseFirestore _db;
  AurenMatchActionFlowRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  String _flowId(AurenMatchItem item) {
    final raw = '${item.kind.name}_${item.id}'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return raw.substring(0, raw.length > 120 ? 120 : raw.length);
  }

  DocumentReference<Map<String, dynamic>> _ref(String uid, AurenMatchItem item) =>
      _db.collection('users').doc(uid).collection('match_action_flows').doc(_flowId(item));

  Future<AurenMatchActionFlowState?> get(String uid, AurenMatchItem item) async {
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
  }) async {
    final safeStep = step.clamp(0, totalSteps - 1);
    final cleanIntent = intent.trim();
    final ref = _ref(uid, item);
    await ref.set({
      'targetId': item.id,
      'targetKind': item.kind.name,
      'action': item.action.name,
      'intent': cleanIntent.length > 1000 ? cleanIntent.substring(0, 1000) : cleanIntent,
      'step': safeStep,
      'status': safeStep >= totalSteps - 1 ? 'completed' : 'active',
      'totalSteps': totalSteps,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final snap = await ref.get();
    return AurenMatchActionFlowState.fromDoc(snap.id, snap.data()!);
  }
}
