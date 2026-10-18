import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/talent.dart';
import '../../core/models/opportunity.dart';
import 'talent_skill_matcher.dart';

class AurenTalentMatch {
  final AurenOpportunity opportunity;
  final int score;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  const AurenTalentMatch({required this.opportunity,required this.score,required this.matchedSkills,required this.missingSkills});
}

class TalentDiscoveryService {
  final FirebaseFirestore db;
  TalentDiscoveryService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;

  Future<List<AurenTalentMatch>> matchOpportunities(AurenTalent talent,{int limit=20}) async {
    final ownerId = talent.ownerId.trim();
    if (ownerId.isEmpty) return const [];
    final safeLimit = limit.clamp(1, 100).toInt();

    final verifiedDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    const pageSize = 200;
    DocumentSnapshot<Map<String, dynamic>>? lastDoc;
    do {
      Query<Map<String, dynamic>> query = db.collection('talent_skill_graph')
          .where('ownerId',isEqualTo:ownerId)
          .where('verified',isEqualTo:true)
          .limit(pageSize);
      if (lastDoc != null) query = query.startAfterDocument(lastDoc);
      final page = await query.get();
      if (page.docs.isEmpty) break;
      verifiedDocs.addAll(page.docs);
      lastDoc = page.docs.last;
      if (page.docs.length < pageSize) break;
    } while (lastDoc != null);
    final userSkills = verifiedDocs
        .map((d) => TalentSkillMatcher.normalize((d.data()['skill'] ?? '').toString()))
        .where((e)=>e.isNotEmpty)
        .toSet();

    if (userSkills.isEmpty) return const [];

    final opportunityDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    const opportunityPageSize = 200;
    DocumentSnapshot<Map<String, dynamic>>? lastOpportunity;
    do {
      Query<Map<String, dynamic>> query = db
          .collection('opportunities')
          .where('status', isEqualTo: 'open')
          .limit(opportunityPageSize);
      if (lastOpportunity != null) {
        query = query.startAfterDocument(lastOpportunity);
      }
      final page = await query.get();
      if (page.docs.isEmpty) break;
      opportunityDocs.addAll(page.docs);
      lastOpportunity = page.docs.last;
      if (page.docs.length < opportunityPageSize) break;
    } while (lastOpportunity != null);

    final matches=<AurenTalentMatch>[];
    for(final d in opportunityDocs){
      final data=d.data();
      final opportunityOwner=(data['ownerId'] ?? '').toString().trim();
      if(opportunityOwner==ownerId) continue;

      final o = AurenOpportunity.fromMap(d.id, data);
      final evaluation = TalentSkillMatcher.evaluate(
        verifiedSkills: userSkills.cast<String>(),
        requiredSkills: o.skills,
      );
      if (evaluation.score > 0) {
        matches.add(AurenTalentMatch(
          opportunity: o,
          score: evaluation.score,
          matchedSkills: evaluation.matchedSkills,
          missingSkills: evaluation.missingSkills,
        ));
      }
    }
    matches.sort((a,b)=>b.score.compareTo(a.score));
    return matches.take(safeLimit).toList();
  }
}
