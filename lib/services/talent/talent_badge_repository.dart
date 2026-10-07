import 'package:cloud_firestore/cloud_firestore.dart';

class TalentBadgeRepository {
  final FirebaseFirestore db;
  TalentBadgeRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> watch(String uid) {
    final cleanUid=uid.trim();
    if(cleanUid.isEmpty) return Stream.value(const []);
    return db.collection('users').doc(cleanUid).collection('talent_badges').orderBy('earnedAt', descending: true).snapshots().map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> evaluate({required String uid, required String talentId, required String displayName, required List<String> sports, required List<String> skills, required List<String> achievements, required List<String> goals}) async {
    final cleanUid=uid.trim();
    final cleanTalentId=talentId.trim();
    if(cleanUid.isEmpty || cleanTalentId.isEmpty) return;
    final ref = db.collection('users').doc(cleanUid).collection('talent_badges');
    final cleanSports = sports.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    final cleanSkills = skills.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    final cleanAchievements = achievements.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    final cleanGoals = goals.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    final rules = <String, String>{'profile_ready': 'Profile Ready', 'multi_sport': 'Multi-Sport', 'skill_builder': 'Skill Builder', 'achievement_proof': 'Achievement Proof', 'goal_setter': 'Goal Setter'};
    final earned = <String>{
      if (displayName.trim().isNotEmpty && cleanSkills.isNotEmpty && cleanGoals.isNotEmpty) 'profile_ready',
      if (cleanSports.length >= 2) 'multi_sport',
      if (cleanSkills.length >= 5) 'skill_builder',
      if (cleanAchievements.isNotEmpty) 'achievement_proof',
      if (cleanGoals.length >= 3) 'goal_setter',
    };
    final batch = db.batch();
    for (final entry in rules.entries) {
      final doc = ref.doc(entry.key);
      if (earned.contains(entry.key)) {
        batch.set(doc, {'ownerId': cleanUid, 'talentId': cleanTalentId, 'badgeId': entry.key, 'title': entry.value, 'earnedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      } else { batch.delete(doc); }
    }
    await batch.commit();
  }
}