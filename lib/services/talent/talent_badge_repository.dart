import 'package:cloud_firestore/cloud_firestore.dart';

class TalentBadgeRepository {
  final FirebaseFirestore db;
  TalentBadgeRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> watch(String uid) => db.collection('users').doc(uid).collection('talent_badges').orderBy('earnedAt', descending: true).snapshots().map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> evaluate({required String uid, required String talentId, required String displayName, required List<String> sports, required List<String> skills, required List<String> achievements, required List<String> goals}) async {
    final ref = db.collection('users').doc(uid).collection('talent_badges');
    final cleanSports = sports.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    final rules = <String, String>{'profile_ready': 'Profile Ready', 'multi_sport': 'Multi-Sport', 'skill_builder': 'Skill Builder', 'achievement_proof': 'Achievement Proof', 'goal_setter': 'Goal Setter'};
    final earned = <String>{
      if (displayName.trim().isNotEmpty && skills.isNotEmpty && goals.isNotEmpty) 'profile_ready',
      if (cleanSports.length >= 2) 'multi_sport',
      if (skills.length >= 5) 'skill_builder',
      if (achievements.isNotEmpty) 'achievement_proof',
      if (goals.length >= 3) 'goal_setter',
    };
    final batch = db.batch();
    for (final entry in rules.entries) {
      final doc = ref.doc(entry.key);
      if (earned.contains(entry.key)) {
        batch.set(doc, {'ownerId': uid, 'talentId': talentId, 'badgeId': entry.key, 'title': entry.value, 'earnedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      } else { batch.delete(doc); }
    }
    await batch.commit();
  }
}