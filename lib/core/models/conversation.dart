import 'package:cloud_firestore/cloud_firestore.dart';

class AurenConversation {
  final String id;
  final List<String> memberIds;
  final String title;
  final bool isAi;
  final DateTime updatedAt;
  final String type;
  final String? ownerId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;

  const AurenConversation({
    required this.id, required this.memberIds, required this.title, required this.isAi,
    required this.updatedAt, this.lastMessage, this.lastMessageAt, this.type = 'direct',
    this.ownerId, this.lastMessageSenderId,
  });

  Map<String, dynamic> toMap() => {
    'memberIds': memberIds, 'title': title, 'isAi': isAi,
    'updatedAt': Timestamp.fromDate(updatedAt.toUtc()),
    if (lastMessage != null) 'lastMessage': lastMessage,
    if (lastMessageAt != null) 'lastMessageAt': Timestamp.fromDate(lastMessageAt!.toUtc()),
    'type': type, if (ownerId != null) 'ownerId': ownerId,
    if (lastMessageSenderId != null) 'lastMessageSenderId': lastMessageSenderId,
  };

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  factory AurenConversation.fromMap(String id, Map<String, dynamic> map) => AurenConversation(
    id: id,
    memberIds: List<String>.from(map['memberIds'] as List? ?? const []),
    title: map['title'] as String? ?? 'Conversation',
    isAi: map['isAi'] as bool? ?? false,
    lastMessage: map['lastMessage'] as String?,
    lastMessageAt: _date(map['lastMessageAt']),
    lastMessageSenderId: map['lastMessageSenderId'] as String?,
    type: map['type'] as String? ?? 'direct',
    ownerId: map['ownerId'] as String?,
    updatedAt: _date(map['updatedAt']) ?? DateTime.now(),
  );
}
