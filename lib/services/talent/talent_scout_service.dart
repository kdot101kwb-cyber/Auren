import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/talent.dart';
import '../../core/models/talent_scout.dart';
import '../../core/models/opportunity.dart';
import '../../core/models/talent_scout_finding.dart';

class TalentScoutService {
  final FirebaseFirestore db;
  TalentScoutService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;

  Stream<List<AurenTalentScoutFinding>> watchFindings(String uid)=>db.collection('users').doc(uid).collection('talent_scout_findings').orderBy('score',descending:true).limit(100).snapshots().map((s)=>s.docs.map((d)=>AurenTalentScoutFinding.fromMap(d.id,d.data())).toList());

  Future<List<AurenTalentScoutFinding>> runNow({required String uid,required List<AurenTalentScout> scouts,required AurenTalent talent,List<AurenOpportunity> opportunities=const []}) async {
    final enabled=scouts.where((s)=>s.enabled).toList();
    final results=<AurenTalentScoutFinding>[];
    final talentSkills=talent.skills.map(_norm).where((x)=>x.isNotEmpty).toSet();
    for(final scout in enabled) {
      if(scout.role=='opportunity') {
        for(final o in opportunities) {
          final required=o.skills.map(_norm).where((x)=>x.isNotEmpty).toSet();
          final matched=required.where(talentSkills.contains).toList();
          final missing=required.difference(talentSkills).toList();
          final score=required.isEmpty?35:((matched.length/required.length)*100).round();
          if(score<25)continue;
          results.add(AurenTalentScoutFinding(id:'${scout.id}_${o.id}',ownerId:uid,scoutId:scout.id,type:'opportunity',title:o.title,description:o.description,sourceType:'opportunity',sourceId:o.id,status:'new',score:score,matchedSkills:matched,missingSkills:missing,createdAt:DateTime.now(),expiresAt:DateTime.now().add(const Duration(days:14))));
        }
      } else {
        final keywords=<String>{...scout.skills.map(_norm),...scout.interests.map(_norm)}..removeWhere((x)=>x.isEmpty);
        final sportSignals=<String>{_norm(talent.sport),_norm(talent.discipline),_norm(talent.level)}..removeWhere((x)=>x.isEmpty);
        final hay='${talent.bio} ${talent.category} ${talent.sport} ${talent.discipline} ${talent.level} ${talent.city} ${talent.country} ${talent.skills.join(' ')}'.toLowerCase();
        final hits=keywords.where((k)=>hay.contains(k)).toList();
        final signalHits=sportSignals.where((signal)=>hay.contains(signal)).toList();
        final baseScore=keywords.isEmpty?50:((hits.length/keywords.length)*100).round();
        final score=(baseScore + signalHits.length * 10).clamp(0, 100).toInt();
        if(score<20&&keywords.isNotEmpty)continue;
        final text=switch(scout.role){
          'market'=>'إشارات سوق مرتبطة بمهاراتك: ${hits.isEmpty?'راجع اتجاهات السوق والمهارات المطلوبة.':hits.join(' • ')}',
          'talent'=>'فرص لاكتشاف مواهب أو فرق مرتبطة بمجالك: ${talent.category.isEmpty?'مجالك الحالي':talent.category}.',
          'brand'=>'أفكار لزيادة ظهورك وبناء علامتك الشخصية حول: ${talent.skills.take(5).join(' • ')}.',
          'learning'=>'مسار تعلم عملي لسد الفجوات حول مهاراتك الحالية: ${talent.skills.take(5).join(' • ')}.',
          'sports'=>'إشارات أداء رياضي لمجالك: ${talent.sport.isEmpty ? talent.category : talent.sport}. راجع التدريب والمهارات والمؤشرات المسجلة قبل أي قرار.',
          _=>'تحليل كشاف المواهب.',
        };
        results.add(AurenTalentScoutFinding(id:'${scout.id}_${talent.id}',ownerId:uid,scoutId:scout.id,type:scout.role,title:scout.name,description:text,sourceType:'talent',sourceId:talent.id,status:'new',score:score,matchedSkills:hits,missingSkills:const [],createdAt:DateTime.now(),expiresAt:DateTime.now().add(const Duration(days:7))));
      }
    }
    final col=db.collection('users').doc(uid).collection('talent_scout_findings');
    for(final f in results) {
      await col.doc(f.id).set({'ownerId':uid,'scoutId':f.scoutId,'type':f.type,'title':f.title,'description':f.description,'sourceType':f.sourceType,'sourceId':f.sourceId,'status':f.status,'score':f.score,'matchedSkills':f.matchedSkills.take(30).toList(),'missingSkills':f.missingSkills.take(30).toList(),'createdAt':FieldValue.serverTimestamp(),'expiresAt':Timestamp.fromDate(f.expiresAt!)},SetOptions(merge:true));
    }
    return results;
  }
  Future<void> markSeen(String uid, String findingId) async {
    await db.collection('users').doc(uid).collection('talent_scout_findings').doc(findingId).update({'status':'seen'});
  }

  Future<void> dismiss(String uid, String findingId) async {
    await db.collection('users').doc(uid).collection('talent_scout_findings').doc(findingId).update({'status':'dismissed'});
  }
  Future<void> markInterested(String uid, String findingId) async {
    await db.collection('users').doc(uid).collection('talent_scout_findings').doc(findingId).update({'status':'interested'});
  }

  Future<List<Map<String, dynamic>>> findSportsMatches({
    required AurenTalent talent,
    List<AurenOpportunity> opportunities = const [],
  }) async {
    final talentSkills = talent.skills.map(_norm).where((x) => x.isNotEmpty).toSet();
    final sports = <String>{...talent.sports.map(_norm), _norm(talent.sport), _norm(talent.discipline)}..removeWhere((x) => x.isEmpty);
    final level = _norm(talent.level);
    final results = <Map<String, dynamic>>[];
    for (final opportunity in opportunities) {
      final hay = _norm('${opportunity.title} ${opportunity.description} ${opportunity.skills.join(' ')}');
      final matchedSkills = opportunity.skills.map(_norm).where(talentSkills.contains).toSet();
      final sportHits = sports.where(hay.contains).toSet();
      final levelHit = level.isNotEmpty && hay.contains(level);
      var score = matchedSkills.length * 15 + sportHits.length * 25 + (levelHit ? 10 : 0);
      final sportsText = '${opportunity.title} ${opportunity.description}'.toLowerCase();
      final sportsContext = ['club','team','coach','academy','sports','football','basketball','volleyball','tennis','boxing','athletics','swimming','cycling','gym','نادي','فريق','مدرب','أكاديمية','رياضة'].any(sportsText.contains);
      if (!sportsContext) continue;
      if (score < 20) score = 20;
      if (score > 100) score = 100;
      results.add({'id': opportunity.id, 'title': opportunity.title, 'description': opportunity.description, 'score': score, 'matchedSkills': matchedSkills.toList(), 'sportHits': sportHits.toList(), 'levelMatch': levelHit});
    }
    results.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    return results.take(50).toList();
  }

  String _norm(String value)=>value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0600-\u06ff ]+'),' ').replaceAll(RegExp(r'\s+'),' ');
}
