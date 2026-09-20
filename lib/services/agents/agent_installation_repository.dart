import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/agent_installation.dart';

class AurenAgentInstallationRepository {
  final FirebaseFirestore _db;

  AurenAgentInstallationRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _installations(String uid) =>
      _db.collection('users').doc(uid).collection('agent_installations');

  Stream<List<AurenAgentInstallation>> watch(String uid) =>
      _installations(uid)
          .orderBy('installedAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => AurenAgentInstallation.fromMap(d.data()))
              .toList());

  Future<bool> isInstalled(String uid, String agentId) async {
    final snap = await _installations(uid).doc(agentId).get();
    return snap.exists;
  }

  Future<void> install({
    required String uid,
    required String agentId,
    required String name,
    required String version,
  }) =>
      _installations(uid).doc(agentId).set({
        'agentId': agentId,
        'name': name,
        'version': version,
        'status': 'active',
        'installedAt': DateTime.now().toIso8601String(),
      });

  Future<void> uninstall(String uid, String agentId) =>
      _installations(uid).doc(agentId).delete();

  Future<void> setStatus(String uid, String agentId, String status) =>
      _installations(uid).doc(agentId).update({'status': status});
}
