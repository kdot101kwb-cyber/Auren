import 'package:cloud_firestore/cloud_firestore.dart';

class AurenTalentCandidate {
  final String uid, mode, headline, bio;
  final List<String> skills, interests, goals, languages, services;
  final bool showContact;
  final int score;
  final List<String> reasons;
  const AurenTalentCandidate({required this.uid,required this.mode,required this.headline,required this.bio,required this.skills,required this.interests,required this.goals,required this.languages,required this.services,required this.showContact,required this.score,required this.reasons});
}

class AurenTalentEngineService {
  final FirebaseFirestore _db;
  AurenTalentEngineService({FirebaseFirestore? db}):_db=db??FirebaseFirestore.instance;

  Future<List<AurenTalentCandidate>> scout({required String query, String? excludeUid, int limit=20}) async {
    final q=_normalize(query);
    if(q.isEmpty) return const [];
    final snap=await _db.collectionGroup('profile_modes').where('discoverable',isEqualTo:true).limit(100).get();
    final candidates=<AurenTalentCandidate>[];
    for(final doc in snap.docs){
      final d=doc.data(); final owner=doc.reference.parent.parent?.id ?? '';
      if(owner.isEmpty || owner==excludeUid) continue;
      final skills=_strings(d['skills']), interests=_strings(d['interests']), goals=_strings(d['goals']), languages=_strings(d['languages']), services=_strings(d['services']);
      final hay=_normalize([d['headline']??'',d['bio']??'',...skills,...interests,...goals,...languages,...services].join(' '));
      final terms=q.split(' ').where((x)=>x.length>1).toSet();
      final hits=terms.where(hay.contains).length;
      if(hits==0) continue;
      final reasons=<String>[];
      if(terms.any((t)=>skills.any((s)=>_normalize(s).contains(t)))) reasons.add('مهارات مطابقة');
      if(terms.any((t)=>services.any((s)=>_normalize(s).contains(t)))) reasons.add('خدمات مناسبة');
      if(terms.any((t)=>goals.any((g)=>_normalize(g).contains(t)))) reasons.add('أهداف متقاربة');
      if(terms.any((t)=>interests.any((i)=>_normalize(i).contains(t)))) reasons.add('اهتمامات مشتركة');
      final score=(45 + hits*12 + (d['mode']=='professional'?5:0)).clamp(0,100);
      candidates.add(AurenTalentCandidate(uid:owner,mode:d['mode']?.toString()??'personal',headline:d['headline']?.toString()??'',bio:d['bio']?.toString()??'',skills:skills,interests:interests,goals:goals,languages:languages,services:services,showContact:d['showContact']==true,score:score,reasons:reasons.isEmpty?const ['مطابقة نصية']:reasons));
    }
    candidates.sort((a,b)=>b.score.compareTo(a.score));
    return candidates.take(limit.clamp(1,50)).toList();
  }

  Future<List<AurenTalentCandidate>> matchOpportunity({required String title,required String description,required List<String> skills,String? excludeUid,int limit=20}) async =>
      scout(query:[title,description,...skills].join(' '),excludeUid:excludeUid,limit:limit);

  Future<void> inviteToOpportunity({required String ownerId,required String talentUid,required String opportunityId,required String opportunityTitle}) async {
    if(ownerId.trim().isEmpty || talentUid.trim().isEmpty || opportunityId.trim().isEmpty) throw ArgumentError('بيانات الدعوة غير مكتملة.');
    if(ownerId == talentUid) throw ArgumentError('لا يمكن دعوة نفسك.');
    final ref=_db.collection('opportunity_invitations').doc('${opportunityId}_$talentUid');
    await ref.set({
      'ownerId': ownerId,
      'talentUid': talentUid,
      'opportunityId': opportunityId,
      'opportunityTitle': opportunityTitle.trim().length > 200 ? opportunityTitle.trim().substring(0,200) : opportunityTitle.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> respondToInvitation({required String invitationId,required String talentUid,required String status}) async {
    if(!['accepted','declined'].contains(status)) throw ArgumentError('حالة الدعوة غير صالحة.');
    final ref=_db.collection('opportunity_invitations').doc(invitationId);
    final snap=await ref.get();
    final data=snap.data();
    if(data==null || data['talentUid'] != talentUid) throw StateError('الدعوة غير موجودة.');
    if(data['status'] != 'pending') throw StateError('تمت معالجة هذه الدعوة بالفعل.');
    await ref.update({'status':status,'updatedAt':FieldValue.serverTimestamp()});
  }

  Stream<List<Map<String,dynamic>>> watchInvitations(String talentUid) => _db.collection('opportunity_invitations')
      .where('talentUid',isEqualTo:talentUid).limit(100).snapshots()
      .map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());

  List<String> _strings(dynamic v)=>v is List?v.whereType<String>().map((x)=>x.trim()).where((x)=>x.isNotEmpty).take(30).toList():const [];
  String _normalize(String value){var s=value.toLowerCase();const marks='\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0670';for(final r in marks.runes){s=s.replaceAll(String.fromCharCode(r),'');}return s.replaceAll('أ','ا').replaceAll('إ','ا').replaceAll('آ','ا').replaceAll('ى','ي').replaceAll('ة','ه').replaceAll('ـ',' ').replaceAll(RegExp(r'\\s+'),' ').trim();}
}