enum WorkflowStatus {
  suggested,
  preparing,
  draft,
  pendingApproval,
  approved,
  executing,
  completed,
  failed,
}

class HumanApprovalRecord {
  final String approvalId;
  final String workflowId;
  final String actionId;
  final String userId;
  final DateTime timestamp;
  final String approvedPayloadHash;

  const HumanApprovalRecord({
    required this.approvalId,
    required this.workflowId,
    required this.actionId,
    required this.userId,
    required this.timestamp,
    required this.approvedPayloadHash,
  });
}

class ActionWorkflow {
  final String workflowId;
  final String actionId;
  final String userId;
  final WorkflowStatus status;
  final Map<String, dynamic> payload;
  final HumanApprovalRecord? approvalRecord;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ActionWorkflow({
    required this.workflowId,
    required this.actionId,
    required this.userId,
    required this.status,
    required this.payload,
    this.approvalRecord,
    this.failureReason,
    required this.createdAt,
    required this.updatedAt,
  });

  ActionWorkflow copyWith({
    WorkflowStatus? status,
    Map<String, dynamic>? payload,
    HumanApprovalRecord? approvalRecord,
    String? failureReason,
    DateTime? updatedAt,
  }) {
    return ActionWorkflow(
      workflowId: workflowId,
      actionId: actionId,
      userId: userId,
      status: status ?? this.status,
      payload: payload ?? this.payload,
      approvalRecord: approvalRecord ?? this.approvalRecord,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}