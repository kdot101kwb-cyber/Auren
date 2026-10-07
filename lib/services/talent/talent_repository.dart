import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/talent.dart';
import 'talent_categories.dart';

class TalentRepository {
  final FirebaseFirestore db;
  TalentRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AurenTalent>> watchPublic({
    String query = '',
    String skill = '',
    String sport = '',
    String category = '',
    bool evidenceOnly = false,
  }) {
    final q = query.trim().toLowerCase();
    final s = skill.trim().toLowerCase();
    final sp = sport.trim().toLowerCase();
    final cat = category.trim().toLowerCase();
    return db.collection('talents').where('status', isEqualTo: 'active').limit(100).snapshots().map((snap) {
      final list = snap.docs.map((d) => AurenTalent.fromMap(d.id, d.data()))
          .where((t) => q.isEmpty || ('${t.displayName} ${t.bio} ${t.category} ${t.sport} ${t.discipline} ${t.level} ${t.city} ${t.country} ${t.skills.join(' ')} ${t.sports.join(' ')} ${t.achievements.join(' ')}').toLowerCase().contains(q))
          .where((t) => s.isEmpty || t.skills.any((x) => x.trim().toLowerCase() == s))
          .where((t) => cat.isEmpty || t.category.trim().toLowerCase() == cat)
          .where((t) => sp.isEmpty || (t.category.trim().toLowerCase() == 'sports' && (t.sport.toLowerCase() == sp || t.sports.any((x) => x.toLowerCase() == sp))))
          .where((t) => !evidenceOnly || t.verificationEvidence.isNotEmpty).toList();
      list.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      return list;
    });
  }

  Future<void> updateVerificationEvidence({required String talentId, required String ownerId, required List<String> evidence}) async {
    final ref = db.collection('talents').doc(talentId);
    final snap = await ref.get();
    if (!snap.exists || snap.data()?['ownerId']?.toString() != ownerId) throw StateError('Not talent owner');
    final cleanEvidence = evidence.map((e) => e.trim()).where((e) => e.isNotEmpty).take(10).toList();
    await ref.update({'verificationEvidence': cleanEvidence, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> saveMissionEvidence({
    required String ownerId,
    required String mission,
    required String category,
    required String result,
    required String evidence,
  }) async {
    await db.collection('talent_mission_evidence').add({
      'ownerId': ownerId,
      'mission': mission.trim(),
      'category': category.trim(),
      'result': result.trim(),
      'evidence': evidence.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

    Future<void> requestSkillVerification({
    required String ownerId,
    required String skill,
  }) async {
    final cleanOwnerId = ownerId.trim();
    final cleanSkill = skill.trim();
    if (cleanOwnerId.isEmpty || cleanSkill.isEmpty) return;
    await db.collection('talent_skill_verification_requests').add({
      'ownerId': cleanOwnerId,
      'skill': cleanSkill,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

Future<List<String>> promoteMissionEvidenceToSkillGraph({
    required String ownerId,
    required List<Map<String, String>> missions,
  }) async {
    final cleanMissions = missions
        .map((m) => {
              'mission': (m['mission'] ?? '').trim(),
              'category': (m['category'] ?? '').trim(),
              'result': (m['result'] ?? '').trim(),
              'evidence': (m['evidence'] ?? '').trim(),
            })
        .where((m) => m['mission']!.isNotEmpty && m['result']!.isNotEmpty)
        .toList();
    if (cleanMissions.isEmpty) return const [];

    const categorySkills = <String, List<String>>{
      'إبداع': ['creative problem solving'],
      'كتابة': ['writing'],
      'حل المشكلات': ['problem solving'],
      'تصميم': ['design thinking'],
      'قيادة': ['leadership'],
      'تحليل': ['analytical thinking'],
      'محتوى': ['content creation'],
      'اكتشاف': ['adaptability'],
    };

    final candidates = <String>{};
    for (final mission in cleanMissions) {
      final skills = categorySkills[mission['category']] ?? const <String>[];
      for (final skill in skills) {
        candidates.add(skill);
        final safeSkill = skill.replaceAll(RegExp(r'[^a-zA-Z0-9_ -]'), '_');
        final ref = db.collection('talent_skill_graph').doc('${ownerId}_$safeSkill');
        final existing = await ref.get();
        final data = existing.data();
        final sameEvidence = existing.exists &&
            data?['lastMission']?.toString() == mission['mission'] &&
            data?['lastResult']?.toString() == mission['result'] &&
            data?['evidence']?.toString() == mission['evidence'];
        final previousCount = (data?['evidenceCount'] as num?)?.toInt() ?? 0;
        final evidenceCount = sameEvidence ? previousCount : previousCount + 1;
        final confidence =
            (0.45 + (evidenceCount - 1) * 0.10).clamp(0.45, 0.85);
        await ref.set({
          'ownerId': ownerId,
          'skill': skill,
          'confidence': confidence,
          'evidenceCount': evidenceCount,
          'source': 'discovery_mission',
          'lastMission': mission['mission'],
          'lastResult': mission['result'],
          'hasEvidence': mission['evidence']!.isNotEmpty,
          'evidence': mission['evidence'],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
    return candidates.toList()..sort();
  }

  Future<String> save({
    required String ownerId, required String displayName, required String bio, required String category,
    String sport = '', String discipline = '', String level = '', required String city, required String country,
    List<String> skills = const [], List<String> achievements = const [], List<String> goals = const [], List<String> sports = const [], List<String> verificationEvidence = const [],
  }) async {
    final ref = db.collection('talents').doc();
    String clean(String value) => value.trim();
    List<String> list(Iterable<String> values, int max) => values.map(clean).where((x) => x.isNotEmpty).take(max).toList();

    final requestedCategory = clean(category).toLowerCase();
    final canonicalCategory = AurenTalentCategories.contains(requestedCategory)
        ? requestedCategory
        : 'other';
    final cleanSport = clean(sport);
    final isSports = canonicalCategory == 'sports';

    await ref.set({
      'ownerId': ownerId,
      'displayName': clean(displayName),
      'bio': clean(bio),
      'category': canonicalCategory,
      'sport': isSports ? cleanSport : '',
      'sports': isSports ? list(sports.isEmpty && cleanSport.isNotEmpty ? [cleanSport] : sports, 10) : <String>[],
      'discipline': clean(discipline),
      'level': clean(level),
      'city': clean(city),
      'country': clean(country),
      'skills': list(skills, 30).map((e) => e.toLowerCase()).toList(),
      'achievements': list(achievements, 20),
      'goals': list(goals, 10),
      'verificationEvidence': list(verificationEvidence, 10),
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
