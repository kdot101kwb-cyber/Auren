import 'package:cloud_firestore/cloud_firestore.dart';

class TalentCoachRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db.collection('users').doc(uid).collection('talent_coach').doc('profile');
  Stream<Map<String, dynamic>?> watch(String uid) => _doc(uid).snapshots().map((s) => s.data());
  Future<void> savePreferences({required String uid, required String coachMode, required String sport, required String level, required String goal, required int weeklySessions}) async {
    await _doc(uid).set({'ownerId': uid, 'coachMode': coachMode, 'sport': sport, 'level': level, 'goal': goal, 'weeklySessions': weeklySessions, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }
}
