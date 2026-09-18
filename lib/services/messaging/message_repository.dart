import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/message.dart';

abstract interface class MessageRepository {
  Stream<List<AurenMessage>> watchConversation(String conversationId);
  Future<void> send(AurenMessage message);
}

class FirestoreMessageRepository implements MessageRepository {
  final FirebaseFirestore _firestore;

  FirestoreMessageRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messages(String conversationId) =>
      _firestore.collection('conversations').doc(conversationId).collection('messages');

  @override
  Stream<List<AurenMessage>> watchConversation(String conversationId) {
    return _messages(conversationId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return AurenMessage(
                id: doc.id,
                conversationId: conversationId,
                senderId: data['senderId'] as String? ?? '',
                text: data['text'] as String? ?? '',
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                isAi: data['isAi'] as bool? ?? false,
              );
            }).toList());
  }

  @override
  Future<void> send(AurenMessage message) {
    return _messages(message.conversationId).doc(message.id).set({
      'senderId': message.senderId,
      'text': message.text,
      'createdAt': Timestamp.fromDate(message.createdAt),
      'isAi': message.isAi,
    });
  }
}
