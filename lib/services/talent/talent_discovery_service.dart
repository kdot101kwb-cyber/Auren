import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/talent.dart';
import '../../core/models/opportunity.dart';

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

  String _norm(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<List<AurenTalentMatch>> matchOpportunities(AurenTalent talent,{int limit=20}) async {
    final ownerId = talent.ownerId.trim();
    if (ownerId.isEmpty) return const [];

    final verifiedSnap = await db.collection('talent_skill_graph')
        .where('ownerId',isEqualTo:ownerId)
        .where('verified',isEqualTo:true)
        .limit(50)
        .get();
    final userSkills = verifiedSnap.docs
        .map((d)=>_norm((d.data()['skill'] ?? '').toString()))
        .where((e)=>e.isNotEmpty)
        .toSet();

    if (userSkills.isEmpty) return const [];

    final snap=await db.collection('opportunities').where('status',isEqualTo:'open').limit(100).get();
    final matches=<AurenTalentMatch>[];
    for(final d in snap.docs){
      final data=d.data();
      final opportunityOwner=(data['ownerId'] ?? '').toString().trim();
      if(opportunityOwner==ownerId) continue;

      final o=AurenOpportunity.fromMap(d.id,data);
      final oppSkills=o.skills.map(_norm).where((e)=>e.isNotEmpty).toSet();
      if(oppSkills.isEmpty) continue;
      final common=userSkills.intersection(oppSkills).toList()..sort();
      final missing=oppSkills.difference(userSkills).toList()..sort();
      final score=((common.length/oppSkills.length)*100).round().clamp(0,100).toInt();
      if(score>0) matches.add(AurenTalentMatch(opportunity:o,score:score,matchedSkills:common,missingSkills:missing));
    }
    matches.sort((a,b)=>b.score.compareTo(a.score));
    return matches.take(limit).toList();
  }
}
