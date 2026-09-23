import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class AurenTypingService {
  final FirebaseFirestore _db;
  Timer? _clearTimer;

  AurenTypingService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _ref(String conversationId, String uid) =>
      _db.collection('conversations').doc(conversationId).collection('typing').doc(uid);

  Future<void> setTyping(String conversationId, String uid, bool typing) async {
    if (conversationId.isEmpty || uid.isEmpty) return;
    if (typing) {
      await _ref(conversationId, uid).set({
        'typing': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await _ref(conversationId, uid).delete();
    }
  }

  Stream<bool> watchTyping(String conversationId, String uid) =>
      _ref(conversationId, uid).snapshots().map((d) {
        final data = d.data();
        if (data?['typing'] != true) return false;
        final updated = data?['updatedAt'];
        if (updated is Timestamp) {
          return DateTime.now().difference(updated.toDate()).inSeconds <= 8;
        }
        return true;
      });

  void scheduleStop(String conversationId, String uid) {
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(seconds: 5), () {
      setTyping(conversationId, uid, false);
    });
  }

  void dispose() => _clearTimer?.cancel();
}
