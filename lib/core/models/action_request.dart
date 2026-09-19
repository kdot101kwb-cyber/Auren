class AurenActionRequest {
  final String id;
  final String conversationId;
  final String title;
  final String description;
  final bool requiresApproval;
  final String status;
  final String? result;
  final DateTime createdAt;

  const AurenActionRequest({
    required this.id,
    required this.conversationId,
    required this.title,
    required this.description,
    required this.requiresApproval,
    required this.status,
    this.result,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'conversationId': conversationId,
        'title': title,
        'description': description,
        'requiresApproval': requiresApproval,
        'status': status,
        'result': result,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory AurenActionRequest.fromMap(
    String id,
    Map<String, dynamic> m,
  ) =>
      AurenActionRequest(
        id: id,
        conversationId: m['conversationId'] as String? ?? '',
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        requiresApproval: m['requiresApproval'] as bool? ?? true,
        status: m['status'] as String? ?? 'pending',
        result: m['result'] as String?,
        createdAt:
            DateTime.tryParse(m['createdAt'] as String? ?? '') ??
                DateTime.now(),
      );
}
