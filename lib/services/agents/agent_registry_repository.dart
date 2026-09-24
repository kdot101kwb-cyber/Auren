import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AurenAgentRegistryRepository {
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  AurenAgentRegistryRepository({
    FirebaseFirestore? db,
    FirebaseFunctions? functions,
  })  : _db = db ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  Stream<List<Map<String, dynamic>>> watchMine(String uid) =>
      _db.collection('users').doc(uid).collection('agents').orderBy('name')
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> save({
    required String uid,
    required String agentId,
    required String name,
    required String version,
    required String status,
  }) async {
    if (uid.trim().isEmpty) throw ArgumentError('User id is required.');
    if (status != 'active') throw ArgumentError('Only active agent creation is supported.');
    await _functions.httpsCallable('saveAurenAgent').call({
      'agentId': agentId.trim(),
      'name': name.trim(),
      'version': version.trim(),
    });
  }
}
