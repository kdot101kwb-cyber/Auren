class AurenActionRequest {
  final String id;
  final String conversationId;
  final String actionType;
  final String title;
  final String description;
  final Map<String, dynamic> payload;
  final String permission;
  final String riskLevel;
  final int approvalLevel;
  final int? spendingLimitMinor;
  final String? currency;
  final bool requiresApproval;
  final String status;
  final String? result;
  final DateTime createdAt;

  const AurenActionRequest({
    required this.id,
    required this.conversationId,
    required this.actionType,
    required this.title,
    required this.description,
    this.payload = const {},
    this.permission = 'standard',
    this.riskLevel = 'low',
    this.approvalLevel = 1,
    this.spendingLimitMinor,
    this.currency,
    required this.requiresApproval,
    required this.status,
    this.result,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'conversationId': conversationId,
        'actionType': actionType,
        'title': title,
        'description': description,
        'payload': payload,
        'permission': permission,
        'riskLevel': riskLevel,
        'approvalLevel': approvalLevel,
        'spendingLimitMinor': spendingLimitMinor,
        'currency': currency,
        'requiresApproval': requiresApproval,
        'status': status,
        'result': result,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory AurenActionRequest.fromMap(String id, Map<String, dynamic> m) =>
      AurenActionRequest(
        id: id,
        conversationId: m['conversationId'] as String? ?? '',
        actionType: m['actionType'] as String? ?? 'unknown',
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        payload: Map<String, dynamic>.from(
          (m['payload'] as Map?) ?? const {},
        ),
        permission: m['permission'] as String? ?? 'standard',
        riskLevel: m['riskLevel'] as String? ?? 'low',
        approvalLevel: (m['approvalLevel'] as num?)?.toInt() ?? 1,
        spendingLimitMinor: (m['spendingLimitMinor'] as num?)?.toInt(),
        currency: m['currency'] as String?,
        requiresApproval: m['requiresApproval'] as bool? ?? true,
        status: m['status'] as String? ?? 'pending',
        result: m['result'] as String?,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
