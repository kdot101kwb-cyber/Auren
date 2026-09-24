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
      .snapshots()
      .map((s) {
        final actions = s.docs
            .map((d) => AurenActionRequest.fromMap(d.id, d.data()))
            .toList();
        actions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return actions;
      });

  Stream<List<AurenActionRequest>> watchOutstanding(String uid) => _actions(uid)
      .snapshots()
      .map((s) {
        final actions = s.docs
            .map((d) => AurenActionRequest.fromMap(d.id, d.data()))
            .where((a) => a.status == 'pending' || a.status == 'approved')
            .toList();
        actions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return actions;
      });

  Stream<List<AurenActionRequest>> watchOutstandingForConversation(
    String uid,
    String conversationId,
  ) =>
      watchOutstanding(uid).map(
        (actions) => actions
            .where((action) => action.conversationId == conversationId)
            .toList(),
      );

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
              .where((a) => a.status != 'pending' && a.status != 'approved')
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
    final normalizedActions = allowedActions
        .map((action) => action.trim())
        .where((action) => action.isNotEmpty)
        .toSet()
        .take(100)
        .toList();
    final normalizedCurrency = currency.trim().toUpperCase();

    if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalizedCurrency)) {
      throw ArgumentError('Currency must be a 3-letter ISO code.');
    }
    if (dailySpendingLimitMinor != null && dailySpendingLimitMinor < 0) {
      throw ArgumentError('Daily spending limit cannot be negative.');
    }

    final ref = _db.collection('users').doc(uid).collection('agent_permissions').doc('primary');
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final current = snapshot.data();
      final spentTodayMinor = current?['spentTodayMinor'] is num
          ? (current!['spentTodayMinor'] as num).toInt()
          : 0;
      final existingCurrency = current?['currency']?.toString().trim().toUpperCase();

      final data = <String, dynamic>{
        'agentId': 'primary',
        'enabled': enabled,
        'allowedActions': normalizedActions,
        'dailySpendingLimitMinor': dailySpendingLimitMinor,
        'spentTodayMinor': spentTodayMinor,
        'spendingDay': current?['spendingDay']?.toString() ?? DateTime.now().toUtc().toIso8601String().substring(0, 10),
        'currency': existingCurrency ?? normalizedCurrency,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      if (snapshot.exists) {
        tx.update(ref, data);
      } else {
        tx.set(ref, data);
      }
    });
  }
 
  Stream<Map<String, dynamic>?> watchTrust(String uid) =>
      _db.collection('users').doc(uid).collection('agent_trust').doc('primary')
          .snapshots().map((s) => s.exists ? s.data() : null);

  Future<AurenActionRequest?> get(String uid, String id) async {
    final snapshot = await _actions(uid).doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AurenActionRequest.fromMap(snapshot.id, snapshot.data()!);
  }
}
