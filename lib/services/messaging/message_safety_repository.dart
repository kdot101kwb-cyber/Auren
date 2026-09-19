import 'package:cloud_firestore/cloud_firestore.dart';

class MessageSafetyRepository {
  final FirebaseFirestore _db;
  MessageSafetyRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> block(String uid, String blockedUid) async {
    if (uid.isEmpty || blockedUid.isEmpty || uid == blockedUid) throw ArgumentError('Invalid block relationship.');
    await _db.collection('message_blocks').doc(uid + '_' + blockedUid).set({
      'ownerUid': uid, 'blockedUid': blockedUid, 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblock(String uid, String blockedUid) async =>
      _db.collection('message_blocks').doc(uid + '_' + blockedUid).delete();

  Stream<bool> watchBlocked(String uid, String blockedUid) =>
      _db.collection('message_blocks').doc(uid + '_' + blockedUid).snapshots().map((doc) => doc.exists);

  Future<void> report({required String reporterUid, required String conversationId, required String messageId, required String reason}) async {
    final clean = reason.trim();
    if (reporterUid.isEmpty || conversationId.isEmpty || messageId.isEmpty || clean.isEmpty || clean.length > 500) throw ArgumentError('Invalid message report.');
    await _db.collection('message_reports').add({
      'reporterUid': reporterUid, 'conversationId': conversationId, 'messageId': messageId,
      'reason': clean, 'createdAt': FieldValue.serverTimestamp(),
    });
  }
}