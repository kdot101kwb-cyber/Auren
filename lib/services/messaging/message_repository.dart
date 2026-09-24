import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/message.dart';

abstract interface class MessageRepository {
  Stream<List<AurenMessage>> watchConversation(String conversationId);
  Future<List<AurenMessage>> recent(String conversationId, {int limit = 20});
  Future<void> send(AurenMessage message);
}

class FirestoreMessageRepository implements MessageRepository {
  final FirebaseFirestore _firestore;
  FirestoreMessageRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messages(String conversationId) =>
      _firestore.collection('conversations').doc(conversationId).collection('messages');

  @override
  Stream<List<AurenMessage>> watchConversation(String conversationId) =>
      _messages(conversationId).orderBy('createdAt').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) {
          final data = doc.data();
          return AurenMessage(
            id: doc.id, conversationId: conversationId,
            senderId: data['senderId'] as String? ?? '',
            text: data['text'] as String? ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isAi: data['isAi'] as bool? ?? false,
          );
        }).toList());

  @override
  Future<List<AurenMessage>> recent(String conversationId, {int limit = 20}) async {
    final snapshot = await _messages(conversationId)
        .orderBy('createdAt', descending: true).limit(limit).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AurenMessage(
        id: doc.id, conversationId: conversationId,
        senderId: data['senderId'] as String? ?? '',
        text: data['text'] as String? ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isAi: data['isAi'] as bool? ?? false,
      );
    }).toList().reversed.toList();
  }

  @override
  Future<void> send(AurenMessage message) async {
    final messageRef = _messages(message.conversationId).doc(message.id);
    await messageRef.set({
      'senderId': message.senderId,
      'text': message.text,
      'createdAt': Timestamp.fromDate(message.createdAt.toUtc()),
      'isAi': message.isAi,
    });
  }
}
