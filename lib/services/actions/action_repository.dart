import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/action_request.dart';

class ActionRepository {
  final FirebaseFirestore _db;

  ActionRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _actions(String uid) =>
      _db.collection('users').doc(uid).collection('actions');

  Future<void> create(String uid, AurenActionRequest action) =>
      _actions(uid).doc(action.id).set(action.toMap());

  Stream<List<AurenActionRequest>> watchPending(String uid) => _actions(uid)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map((d) => AurenActionRequest.fromMap(d.id, d.data())).toList());

  /// Includes approved actions so a temporary network/backend failure does not
  /// strand a user-approved action outside the Action Center.
  Stream<List<AurenActionRequest>> watchOutstanding(String uid) => _actions(uid)
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs
          .map((d) => AurenActionRequest.fromMap(d.id, d.data()))
          .where((a) => a.status == 'pending' || a.status == 'approved')
          .toList());

  /// Recent terminal actions are kept visible for transparency and auditing.
  Stream<List<Map<String, dynamic>>> watchAudit(String uid, {int limit = 20}) =>
      _db.collection('users').doc(uid).collection('action_audit')
          .orderBy('createdAt', descending: true).limit(limit).snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<AurenActionRequest>> watchHistory(String uid, {int limit = 30}) =>
      _actions(uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs
              .map((d) => AurenActionRequest.fromMap(d.id, d.data()))
              .where((a) =>
                  a.status != 'pending' && a.status != 'approved')
              .toList());

  Stream<Map<String, dynamic>?> watchPermissionLedger(String uid) =>
      _db.collection('users').doc(uid).collection('agent_permissions').doc('primary')
          .snapshots().map((s) => s.exists ? s.data() : null);

  Future<void> setPermissionLedger(String uid, {
    required bool enabled,
    required List<String> allowedActions,
    int? dailySpendingLimitMinor,
    String currency = 'USD',
  }) async {
    await _db.collection('users').doc(uid).collection('agent_permissions').doc('primary').set({
      'agentId': 'primary',
      'enabled': enabled,
      'allowedActions': allowedActions,
      'dailySpendingLimitMinor': dailySpendingLimitMinor,
      'spentTodayMinor': 0,
      'currency': currency,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> watchTrust(String uid) =>
      _db.collection('users').doc(uid).collection('agent_trust').doc('primary')
          .snapshots().map((s) => s.exists ? s.data() : null);

  Future<AurenActionRequest?> get(String uid, String id) async {
    final snapshot = await _actions(uid).doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AurenActionRequest.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<void> setStatus(
    String uid,
    String id,
    String status, {
    String? result,
  }) =>
      _actions(uid).doc(id).update({
        'status': status,
        if (result != null) 'result': result,
      });
}
