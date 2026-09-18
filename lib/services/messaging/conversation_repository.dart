import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/conversation.dart';

class ConversationRepository {
  final FirebaseFirestore _firestore;

  ConversationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  Future<AurenConversation> createAiConversation(String uid) async {
    final ref = _conversations.doc();
    final conversation = AurenConversation(
      id: ref.id,
      memberIds: [uid],
      title: 'AUREN AI',
      isAi: true,
      updatedAt: DateTime.now(),
    );

    await ref.set(conversation.toMap());
    return conversation;
  }

  Future<AurenConversation?> findAiConversation(String uid) async {
    final snapshot = await _conversations
        .where('memberIds', arrayContains: uid)
        .where('isAi', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return AurenConversation.fromMap(doc.id, doc.data());
  }

  Future<AurenConversation> getOrCreateAiConversation(String uid) async {
    return await findAiConversation(uid) ?? createAiConversation(uid);
  }

  Future<void> touch(String conversationId) {
    return _conversations.doc(conversationId).update({
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
