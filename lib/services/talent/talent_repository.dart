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
          .where((t) => sp.isEmpty || (t.category.trim().toLowerCase() == 'sports' && (t.sport.trim().toLowerCase() == sp || t.sports.any((x) => x.trim().toLowerCase() == sp))))
          .where((t) => !evidenceOnly || t.verificationEvidence.isNotEmpty).toList();
      list.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      return list;
    });
  }

  Future<void> updateVerificationEvidence({required String talentId, required String ownerId, required List<String> evidence}) async {
    final ref = db.collection('talents').doc(talentId);
    final snap = await ref.get();
    if (!snap.exists || snap.data()?['ownerId']?.toString() != ownerId.trim()) throw StateError('Not talent owner');
    final cleanEvidence = evidence.map((e) => e.trim()).toList();
    if (cleanEvidence.length > 10 ||
        cleanEvidence.any((e) => e.isEmpty || e.length > 1200)) {
      throw ArgumentError('أدلة التحقق تتجاوز الحد المسموح.');
    }
    await ref.update({'verificationEvidence': cleanEvidence, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> saveMissionEvidence({
    required String ownerId,
    required String mission,
    required String category,
    required String result,
    required String evidence,
  }) async {
    final cleanOwnerId = ownerId.trim();
    final cleanMission = mission.trim();
    final cleanCategory = category.trim();
    final cleanResult = result.trim();
    final cleanEvidence = evidence.trim();

    if (cleanOwnerId.isEmpty ||
        cleanMission.isEmpty ||
        cleanCategory.isEmpty ||
        cleanResult.isEmpty) {
      throw ArgumentError('بيانات المهمة غير مكتملة.');
    }
    if (cleanOwnerId.length > 128 ||
        cleanMission.length > 200 ||
        cleanCategory.length > 80 ||
        cleanResult.length > 1000 ||
        cleanEvidence.length > 1200) {
      throw ArgumentError('بيانات المهمة تتجاوز الحد المسموح.');
    }

    await db.collection('talent_mission_evidence').add({
      'ownerId': cleanOwnerId,
      'mission': cleanMission,
      'category': cleanCategory,
      'result': cleanResult,
      'evidence': cleanEvidence,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, String>>> loadMissionEvidence({
    required String ownerId,
  }) async {
    final cleanOwnerId = ownerId.trim();
    if (cleanOwnerId.isEmpty) return const [];

    final missions = <Map<String, String>>[];
    const pageSize = 200;
    DocumentSnapshot<Map<String, dynamic>>? lastDoc;
    do {
      var query = db
          .collection('talent_mission_evidence')
          .where('ownerId', isEqualTo: cleanOwnerId)
          .orderBy('createdAt', descending: true)
          .limit(pageSize);
      if (lastDoc != null) query = query.startAfterDocument(lastDoc!);
      final page = await query.get();
      if (page.docs.isEmpty) break;
      for (final doc in page.docs) {
        final data = doc.data();
        missions.add({
          'mission': (data['mission'] ?? '').toString().trim(),
          'category': (data['category'] ?? '').toString().trim(),
          'result': (data['result'] ?? '').toString().trim(),
          'evidence': (data['evidence'] ?? '').toString().trim(),
        });
      }
      lastDoc = page.docs.last;
      if (page.docs.length < pageSize) break;
    } while (lastDoc != null);

    return missions;
  }

  Future<void> requestSkillVerification({
    required String ownerId,
    required String skill,
  }) async {
    final cleanOwnerId = ownerId.trim();
    final cleanSkill = skill.trim();
    if (cleanOwnerId.isEmpty || cleanSkill.isEmpty) {
      throw ArgumentError('بيانات طلب التحقق غير مكتملة.');
    }
    if (cleanOwnerId.length > 128 || cleanSkill.length > 120) {
      throw ArgumentError('بيانات طلب التحقق طويلة جدًا.');
    }
    final existing = await db
        .collection('talent_skill_verification_requests')
        .where('ownerId', isEqualTo: cleanOwnerId)
        .where('status', isEqualTo: 'pending')
        .limit(100)
        .get();
    if (existing.docs.any((doc) =>
        doc.data()['status']?.toString() == 'pending' &&
        doc.data()['skill']?.toString().trim().toLowerCase() == cleanSkill.toLowerCase())) {
      return;
    }
    await db.collection('talent_skill_verification_requests').add({
      'ownerId': cleanOwnerId,
      'skill': cleanSkill,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> promoteSavedMissionEvidenceToSkillGraph({
    required String ownerId,
  }) async {
    final cleanOwnerId = ownerId.trim();
    if (cleanOwnerId.isEmpty) return const [];

    final saved = await loadMissionEvidence(ownerId: cleanOwnerId);
    return promoteMissionEvidenceToSkillGraph(
      ownerId: cleanOwnerId,
      missions: saved,
    );
  }

  Future<List<String>> promoteMissionEvidenceToSkillGraph({
    required String ownerId,
    required List<Map<String, String>> missions,
  }) async {
    final cleanOwnerId = ownerId.trim();
    if (cleanOwnerId.isEmpty || cleanOwnerId.length > 128) {
      throw ArgumentError('معرّف مالك الموهبة غير صالح.');
    }

    final cleanMissions = missions
        .map((m) => {
              'mission': (m['mission'] ?? '').trim(),
              'category': (m['category'] ?? '').trim(),
              'result': (m['result'] ?? '').trim(),
              'evidence': (m['evidence'] ?? '').trim(),
            })
        .where((m) =>
            m['mission']!.isNotEmpty &&
            m['result']!.isNotEmpty &&
            m['mission']!.length <= 200 &&
            m['category']!.length <= 80 &&
            m['result']!.length <= 1000 &&
            m['evidence']!.length <= 1200)
        .toList();
    if (cleanMissions.isEmpty) return const [];

    const categorySkills = <String, String>{
      'إبداع': 'creative problem solving',
      'كتابة': 'writing',
      'حل المشكلات': 'problem solving',
      'تصميم': 'design thinking',
      'قيادة': 'leadership',
      'تحليل': 'analytical thinking',
      'محتوى': 'content creation',
      'اكتشاف': 'adaptability',
    };

    final candidates = <String>{};
    for (final skillEntry in categorySkills.entries) {
      final matchingMissions = cleanMissions
          .where((mission) => mission['category'] == skillEntry.key)
          .toList();
      if (matchingMissions.isEmpty) continue;

      final uniqueEvidence = <String, Map<String, String>>{};
      for (final mission in matchingMissions) {
        final key = [
          mission['mission']!,
          mission['result']!,
          mission['evidence']!,
        ].join('\u001f');
        uniqueEvidence[key] = mission;
      }

      final skill = skillEntry.value;
      candidates.add(skill);
      final safeSkill = skill.replaceAll(RegExp(r'[^a-zA-Z0-9_ -]'), '_');
      final ref = db.collection('talent_skill_graph').doc('${cleanOwnerId}_$safeSkill');
      final evidenceCount = uniqueEvidence.length;
      final confidence =
          (0.45 + (evidenceCount - 1) * 0.10).clamp(0.45, 0.85);
      final latest = matchingMissions.first;

      await ref.set({
          'ownerId': cleanOwnerId,
          'skill': skill,
          'confidence': confidence,
          'evidenceCount': evidenceCount,
          'source': 'discovery_mission',
          'lastMission': latest['mission'],
          'lastResult': latest['result'],
          'hasEvidence': latest['evidence']!.isNotEmpty,
          'evidence': latest['evidence'],
          'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return candidates.toList()..sort();
  }

  Future<String> save({
    required String ownerId, required String displayName, required String bio, required String category,
    String sport = '', String discipline = '', String level = '', required String city, required String country,
    List<String> skills = const [], List<String> achievements = const [], List<String> goals = const [], List<String> sports = const [], List<String> verificationEvidence = const [],
  }) async {
    final cleanOwnerId = ownerId.trim();
    final cleanDisplayName = displayName.trim();
    final cleanBio = bio.trim();
    final cleanCity = city.trim();
    final cleanCountry = country.trim();
    if (cleanOwnerId.isEmpty || cleanDisplayName.isEmpty || cleanCity.isEmpty || cleanCountry.isEmpty) {
      throw ArgumentError('بيانات ملف الموهبة الأساسية غير مكتملة.');
    }
    if (cleanOwnerId.length > 128 || cleanDisplayName.length > 120 || cleanBio.length > 2000 || cleanCity.length > 100 || cleanCountry.length > 100) {
      throw ArgumentError('بيانات ملف الموهبة تتجاوز الحد المسموح.');
    }

    final ref = db.collection('talents').doc();
    String clean(String value) => value.trim();
    List<String> list(Iterable<String> values, int max, int maxLength, String fieldName) {
      final cleaned = values.map(clean).toList();
      if (cleaned.length > max ||
          cleaned.any((x) => x.isEmpty || x.length > maxLength)) {
        throw ArgumentError('$fieldName تتجاوز الحد المسموح.');
      }
      return cleaned;
    }

    final requestedCategory = clean(category).toLowerCase();
    final canonicalCategory = AurenTalentCategories.contains(requestedCategory)
        ? requestedCategory
        : 'other';
    final cleanSport = clean(sport);
    final cleanDiscipline = clean(discipline);
    final cleanLevel = clean(level);
    if (cleanSport.length > 80 || cleanDiscipline.length > 100 || cleanLevel.length > 60) {
      throw ArgumentError('بيانات التخصص الرياضي تتجاوز الحد المسموح.');
    }
    final isSports = canonicalCategory == 'sports';

    await ref.set({
      'ownerId': cleanOwnerId,
      'displayName': cleanDisplayName,
      'bio': cleanBio,
      'category': canonicalCategory,
      'sport': isSports ? cleanSport : '',
      'sports': isSports
          ? list(
              sports.isEmpty && cleanSport.isNotEmpty ? [cleanSport] : sports,
              10,
              80,
              'الرياضات',
            )
          : <String>[],
      'discipline': cleanDiscipline,
      'level': cleanLevel,
      'city': cleanCity,
      'country': cleanCountry,
      'skills': list(skills, 30, 120, 'المهارات')
          .map((e) => e.toLowerCase())
          .toList(),
      'achievements': list(achievements, 20, 500, 'الإنجازات'),
      'goals': list(goals, 10, 300, 'الأهداف'),
      'verificationEvidence': list(
        verificationEvidence,
        10,
        1200,
        'أدلة التحقق',
      ),
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
