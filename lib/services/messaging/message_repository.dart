import '../../core/models/message.dart';

abstract interface class MessageRepository {
  Stream<List<AurenMessage>> watchConversation(String conversationId);
  Future<void> send(AurenMessage message);
}

/// Temporary in-memory repository. Replace with Firestore implementation without changing UI.
class InMemoryMessageRepository implements MessageRepository {
  final Map<String, List<AurenMessage>> _data = {};
  @override Stream<List<AurenMessage>> watchConversation(String conversationId) async* { yield List.unmodifiable(_data[conversationId] ?? const []); }
  @override Future<void> send(AurenMessage message) async { (_data[message.conversationId] ??= []).add(message); }
}
