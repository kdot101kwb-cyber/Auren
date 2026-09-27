import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
    if (uid.trim().isEmpty) throw ArgumentError('User id is required.');
    final normalizedActions = allowedActions.map((a) => a.trim()).where((a) => a.isNotEmpty).toSet().take(100).toList();
    if (normalizedActions.any((a) => a.length > 80 || !RegExp(r'^[a-z0-9._:-]+$', caseSensitive: false).hasMatch(a))) {
      throw ArgumentError('Invalid agent action.');
    }
    if (dailySpendingLimitMinor != null && dailySpendingLimitMinor < 0) {
      throw ArgumentError('Daily spending limit cannot be negative.');
    }
    final normalizedCurrency = currency.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalizedCurrency)) {
      throw ArgumentError('Currency must be a 3-letter ISO code.');
    }
    await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('setAurenAgentPermissions')
        .call({
          'enabled': enabled,
          'allowedActions': normalizedActions,
          'dailySpendingLimitMinor': dailySpendingLimitMinor,
          'currency': normalizedCurrency,
        });
  }

  Stream<Map<String, dynamic>?> watchTrust(String uid) =>
      _db.collection('users').doc(uid).collection('agent_trust').doc('primary')
          .snapshots().map((s) => s.exists ? s.data() : null);

  Future<String> approve(String actionId) async {
    final id = actionId.trim();
    if (id.isEmpty) throw ArgumentError('Action id is required.');
    final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('approveAurenAction')
        .call({'actionId': id});
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['status']?.toString() ?? 'approved';
  }

  Future<String> reject(String actionId) async {
    final id = actionId.trim();
    if (id.isEmpty) throw ArgumentError('Action id is required.');
    final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('rejectAurenAction')
        .call({'actionId': id});
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['status']?.toString() ?? 'rejected';
  }

  Future<String> execute(String actionId) async {
    final id = actionId.trim();
    if (id.isEmpty) throw ArgumentError('Action id is required.');
    final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('executeAurenAction')
        .call({'actionId': id});
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['status']?.toString() ?? 'completed';
  }

  Future<String> cancel(String actionId) async {
    final id = actionId.trim();
    if (id.isEmpty) throw ArgumentError('Action id is required.');
    final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('cancelAurenAction')
        .call({'actionId': id});
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['status']?.toString() ?? 'cancelled';
  }

  Future<AurenActionRequest?> get(String uid, String id) async {
    final snapshot = await _actions(uid).doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AurenActionRequest.fromMap(snapshot.id, snapshot.data()!);
  }
}
