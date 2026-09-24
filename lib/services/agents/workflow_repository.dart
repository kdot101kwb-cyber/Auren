import 'package:cloud_firestore/cloud_firestore.dart';

class AurenWorkflowSummary {
  final String workflowId;
  final String state;
  final int currentStep;
  final int totalSteps;
  final String currentAgent;
  final String? pendingTaskId;
  final int completedSteps;
  final int failedSteps;
  final DateTime? updatedAt;

  const AurenWorkflowSummary({
    required this.workflowId,
    required this.state,
    required this.currentStep,
    required this.totalSteps,
    required this.currentAgent,
    this.pendingTaskId,
    required this.completedSteps,
    required this.failedSteps,
    this.updatedAt,
  });

  factory AurenWorkflowSummary.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final rawUpdated = data['updatedAt'];
    return AurenWorkflowSummary(
      workflowId: data['workflowId']?.toString() ?? id,
      state: data['state']?.toString() ?? 'active',
      currentStep: (data['currentStep'] as num?)?.toInt() ?? 0,
      totalSteps: (data['totalSteps'] as num?)?.toInt() ?? 0,
      currentAgent: data['currentAgent']?.toString() ?? '',
      pendingTaskId: data['pendingTaskId']?.toString(),
      completedSteps: (data['completedSteps'] as num?)?.toInt() ?? 0,
      failedSteps: (data['failedSteps'] as num?)?.toInt() ?? 0,
      updatedAt: rawUpdated is Timestamp ? rawUpdated.toDate() : null,
    );
  }
}

class AurenWorkflowRepository {
  final FirebaseFirestore db;

  AurenWorkflowRepository({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AurenWorkflowSummary>> watch(String uid) => db
      .collection('users')
      .doc(uid)
      .collection('agent_workflows')
      .orderBy('updatedAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => AurenWorkflowSummary.fromMap(doc.id, doc.data()))
          .toList());

  Future<AurenWorkflowSummary?> get(
    String uid,
    String workflowId,
  ) async {
    final doc = await db
        .collection('users')
        .doc(uid)
        .collection('agent_workflows')
        .doc(workflowId)
        .get();
    return doc.exists
        ? AurenWorkflowSummary.fromMap(doc.id, doc.data() ?? const {})
        : null;
  }
}
