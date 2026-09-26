import 'package:cloud_firestore/cloud_firestore.dart';

class AurenSafetyRepository {
  final FirebaseFirestore _db;
  AurenSafetyRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _blocked(String uid) =>
      _db.collection('users').doc(uid).collection('blocked');

  Stream<bool> watchBlocked(String uid, String otherUid) =>
      _blocked(uid).doc(otherUid).snapshots().map((s) => s.exists);

  Future<void> block(String uid, String otherUid) async {
    if (uid.isEmpty || otherUid.isEmpty || uid == otherUid) {
      throw ArgumentError('Invalid block target.');
    }
    await _blocked(uid).doc(otherUid).set({
      'blockedUid': otherUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblock(String uid, String otherUid) =>
      _blocked(uid).doc(otherUid).delete();

  Future<void> report({
    required String reporterUid,
    required String reportedUid,
    required String reason,
    String? contentId,
    String? contentType,
  }) async {
    final cleanReason = reason.trim();
    if (reporterUid.isEmpty || reportedUid.isEmpty || reporterUid == reportedUid ||
        cleanReason.isEmpty || cleanReason.length > 500) {
      throw ArgumentError('Invalid report.');
    }
    await _db.collection('reports').add({
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reason': cleanReason,
      'contentId': contentId,
      'contentType': contentType,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
