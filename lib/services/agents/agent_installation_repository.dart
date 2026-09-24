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

  // Installation lifecycle is server-controlled through Cloud Functions.
  // This repository intentionally exposes read-only access to avoid bypassing
  // validation, permissions, quotas, and audit logging.
}
