import 'package:cloud_firestore/cloud_firestore.dart';

class AurenWorkArtifact {
  final String id;
  final String type;
  final String domain;
  final String title;
  final String body;
  final String status;
  final String? executionId;
  final String? actionId;
  final String? agentId;
  final Map<String,dynamic> payload;

  const AurenWorkArtifact({
    required this.id,
    required this.type,
    required this.domain,
    required this.title,
    required this.body,
    required this.status,
    this.executionId,
    this.actionId,
    this.agentId,
    this.payload=const {},
  });

  factory AurenWorkArtifact.fromDoc(String id, Map<String,dynamic> data) {
    return AurenWorkArtifact(
      id:id,
      type:(data['type']??'').toString(),
      domain:(data['domain']??'general').toString(),
      title:(data['title']??'').toString(),
      body:(data['body']??'').toString(),
      status:(data['status']??'draft').toString(),
      executionId:data['executionId']?.toString(),
      actionId:data['actionId']?.toString(),
      agentId:data['agentId']?.toString(),
      payload:data['payload'] is Map
        ? Map<String,dynamic>.from(data['payload'] as Map)
        : const {},
    );
  }

  static AurenWorkArtifact fromSnapshot(DocumentSnapshot<Map<String,dynamic>> doc) =>
      AurenWorkArtifact.fromDoc(doc.id, doc.data() ?? const {});
}
