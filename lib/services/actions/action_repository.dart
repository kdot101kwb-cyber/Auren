import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/action_request.dart';

class ActionRepository {
  final FirebaseFirestore _db;

  ActionRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _actions(String uid) =>
      _db.collection('users').doc(uid).collection('actions');

  Future<void> create(String uid, AurenActionRequest action) =>
      _actions(uid).doc(action.id).set(action.toMap());

  Stream<List<AurenActionRequest>> watchPending(String uid) => _actions(uid)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map((d) => AurenActionRequest.fromMap(d.id, d.data())).toList());

  /// Includes approved actions so a temporary network/backend failure does not
  /// strand a user-approved action outside the Action Center.
  Stream<List<AurenActionRequest>> watchOutstanding(String uid) => _actions(uid)
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs
          .map((d) => AurenActionRequest.fromMap(d.id, d.data()))
          .where((a) => a.status == 'pending' || a.status == 'approved')
          .toList());

  Future<AurenActionRequest?> get(String uid, String id) async {
    final snapshot = await _actions(uid).doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AurenActionRequest.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<void> setStatus(
    String uid,
    String id,
    String status, {
    String? result,
  }) =>
      _actions(uid).doc(id).update({
        'status': status,
        if (result != null) 'result': result,
      });
}
