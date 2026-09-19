class AurenConversation {
  final String id;
  final List<String> memberIds;
  final String title;
  final bool isAi;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const AurenConversation({
    required this.id,
    required this.memberIds,
    required this.title,
    required this.isAi,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageAt,
  });

  Map<String, dynamic> toMap() => {
        'memberIds': memberIds,
        'title': title,
        'isAi': isAi,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        if (lastMessage != null) 'lastMessage': lastMessage,
        if (lastMessageAt != null) 'lastMessageAt': lastMessageAt!.toUtc().toIso8601String(),
      };

  factory AurenConversation.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return AurenConversation(
      id: id,
      memberIds: List<String>.from(map['memberIds'] as List? ?? const []),
      title: map['title'] as String? ?? 'Conversation',
      isAi: map['isAi'] as bool? ?? false,
      lastMessage: map['lastMessage'] as String?,
      lastMessageAt: DateTime.tryParse(map['lastMessageAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(
            map['updatedAt'] as String? ?? '',
          )?.toLocal() ??
          DateTime.now(),
    );
  }
}
