import 'package:cloud_firestore/cloud_firestore.dart';

class AurenWorkAction {
  final String id;
  final String executionId;
  final String agentId;
  final String actionType;
  final String title;
  final String preview;
  final String status;
  final Map<String,dynamic> payload;
  final bool requiresApproval;
  final bool externalSideEffects;
  final dynamic result;
  final String? error;

  const AurenWorkAction({
    required this.id, required this.executionId, required this.agentId,
    required this.actionType, required this.title, required this.preview,
    required this.status, this.payload=const {}, required this.requiresApproval,
    required this.externalSideEffects, this.result, this.error,
  });

  static Map<String,dynamic> _map(dynamic value) =>
      value is Map ? Map<String,dynamic>.from(value as Map) : const {};

  factory AurenWorkAction.fromDoc(String id, Map<String,dynamic> data) =>
      AurenWorkAction(
        id:id,
        executionId:(data['executionId']??'').toString(),
        agentId:(data['agentId']??'').toString(),
        actionType:(data['actionType']??'').toString(),
        title:(data['title']??'').toString(),
        preview:(data['preview']??'').toString(),
        status:(data['status']??'proposed').toString(),
        payload:_map(data['payload']),
        requiresApproval:data['requiresApproval']==true,
        externalSideEffects:data['externalSideEffects']==true,
        result:data['result'],
        error:data['error']?.toString(),
      );
}
