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

  Future<List<AurenTalentMatch>> matchOpportunities(AurenTalent talent,{int limit=20}) async {
    final snap=await db.collection('opportunities').where('status',isEqualTo:'open').limit(100).get();
    final userSkills=talent.skills.map(_norm).where((e)=>e.isNotEmpty).toSet();
    final matches=<AurenTalentMatch>[];
    for(final d in snap.docs){
      final o=AurenOpportunity.fromMap(d.id,d.data());
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

  static String _norm(String value)=>value.trim().toLowerCase().replaceAll(RegExp(r'\\s+'),' ');
}
