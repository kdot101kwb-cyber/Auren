import 'package:cloud_firestore/cloud_firestore.dart';

class AurenTalentAgent {
  final String id, ownerId, talentId, name, role, description;
  final bool enabled;
  final List<String> capabilities;
  final DateTime? updatedAt;

  const AurenTalentAgent({
    required this.id, required this.ownerId, required this.talentId,
    required this.name, required this.role, required this.description,
    required this.enabled, required this.capabilities, this.updatedAt,
  });

  factory AurenTalentAgent.fromMap(String id, Map<String, dynamic> data) {
    final raw = data['capabilities'];
    return AurenTalentAgent(
      id: id, ownerId: data['ownerId']?.toString() ?? '',
      talentId: data['talentId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      role: data['role']?.toString() ?? 'career',
      description: data['description']?.toString() ?? '',
      enabled: data['enabled'] == true,
      capabilities: raw is List ? raw.map((e) => e.toString()).take(20).toList() : const [],
      updatedAt: data['updatedAt'] is Timestamp ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}
