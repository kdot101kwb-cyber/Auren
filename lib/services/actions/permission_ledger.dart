import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/agent_permission.dart';

class AurenPermissionLedger {
  final FirebaseFirestore _db;

  AurenPermissionLedger({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      _db.collection('users').doc(uid).collection('agent_permissions').doc('primary');

  Future<AurenAgentPermission?> get(String uid) async {
    final snap = await _ref(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return AurenAgentPermission(
      agentId: data['agentId'] as String? ?? 'primary',
      enabled: data['enabled'] as bool? ?? true,
      allowedActions: Set<String>.from(
        (data['allowedActions'] as List?)?.whereType<String>() ?? const [],
      ),
      dailySpendingLimitMinor: (data['dailySpendingLimitMinor'] as num?)?.toInt(),
      spentTodayMinor: (data['spentTodayMinor'] as num?)?.toInt() ?? 0,
      currency: data['currency'] as String? ?? 'USD',
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Future<void> save(String uid, AurenAgentPermission permission) =>
      _ref(uid).set(permission.toMap(), SetOptions(merge: true));
}
