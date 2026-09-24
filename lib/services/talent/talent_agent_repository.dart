import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/talent_agent.dart';

class TalentAgentRepository {
  final FirebaseFirestore db;
  TalentAgentRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _agents(String uid) =>
      db.collection('users').doc(uid).collection('talent_agents');

  Stream<List<AurenTalentAgent>> watch(String uid) => _agents(uid)
      .orderBy('updatedAt', descending: true).limit(50).snapshots()
      .map((s) => s.docs.map((d) => AurenTalentAgent.fromMap(d.id, d.data())).toList());

  Future<String> upsert({
    required String ownerId, required String talentId, required String name,
    required String role, required String description, required List<String> capabilities,
  }) async {
    final id = '${talentId}_${role}'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    await _agents(ownerId).doc(id).set({
      'ownerId': ownerId, 'talentId': talentId, 'name': name.trim(),
      'role': role.trim().toLowerCase(), 'description': description.trim(),
      'enabled': true,
      'capabilities': capabilities.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).take(20).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return id;
  }

  Future<void> setEnabled(String uid, String agentId, bool enabled) =>
      _agents(uid).doc(agentId).update({'enabled': enabled, 'updatedAt': FieldValue.serverTimestamp()});
}
