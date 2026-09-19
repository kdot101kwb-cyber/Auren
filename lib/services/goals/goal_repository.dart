import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/goal.dart';

class GoalRepository {
  final FirebaseFirestore _db;
  GoalRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _goals(String uid) =>
      _db.collection('users').doc(uid).collection('goals');

  Stream<List<AurenGoal>> watch(String uid) => _goals(uid)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((d) => AurenGoal.fromMap(d.id, d.data())).toList());

  Future<void> upsert(String uid, AurenGoal goal) => _goals(uid).doc(goal.id).set(goal.toMap());
  Future<void> delete(String uid, String id) => _goals(uid).doc(id).delete();
}
