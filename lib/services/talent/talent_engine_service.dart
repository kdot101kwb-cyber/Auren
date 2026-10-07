import 'package:cloud_firestore/cloud_firestore.dart';

class AurenTalentCandidate {
  final String uid, mode, headline, bio;
  final List<String> skills, verifiedSkills, interests, goals, languages, services;
  final bool showContact;
  final int score;
  final List<String> reasons;
  const AurenTalentCandidate({required this.uid,required this.mode,required this.headline,required this.bio,required this.skills,required this.verifiedSkills,required this.interests,required this.goals,required this.languages,required this.services,required this.showContact,required this.score,required this.reasons});
}

class AurenTalentEngineService {
  final FirebaseFirestore _db;
  AurenTalentEngineService({FirebaseFirestore? db}):_db=db??FirebaseFirestore.instance;

  Future<List<AurenTalentCandidate>> scout({required String query, String? excludeUid, int limit=20}) async {
    final q=_normalize(query);
    if(q.isEmpty) return const [];
    // Page discoverable profiles so candidates beyond the first 500 are
    // not silently excluded as the public profile-mode collection grows.
    final profileDocs=<QueryDocumentSnapshot<Map<String,dynamic>>>[];
    const profilePageSize=500;
    DocumentSnapshot<Map<String,dynamic>>? lastProfileDoc;
    do {
      Query<Map<String,dynamic>> profileQuery=_db.collectionGroup('profile_modes')
          .where('discoverable',isEqualTo:true)
          .limit(profilePageSize);
      if(lastProfileDoc!=null) profileQuery=profileQuery.startAfterDocument(lastProfileDoc!);
      final page=await profileQuery.get();
      if(page.docs.isEmpty) break;
      profileDocs.addAll(page.docs);
      lastProfileDoc=page.docs.last;
      if(page.docs.length<profilePageSize) break;
    } while(lastProfileDoc!=null);
    // Load the complete verified Skill Graph in pages. A global limit could
    // otherwise hide a candidate's verified skill when the collection grows.
    final verifiedByOwner=<String,List<String>>{};
    const pageSize=500;
    DocumentSnapshot<Map<String,dynamic>>? lastVerifiedDoc;
    do {
      Query<Map<String,dynamic>> query=_db.collection('talent_skill_graph')
          .where('verified',isEqualTo:true)
          .limit(pageSize);
      if(lastVerifiedDoc!=null) query=query.startAfterDocument(lastVerifiedDoc!);
      final page=await query.get();
      if(page.docs.isEmpty) break;
      for(final skillDoc in page.docs){
        final data=skillDoc.data();
        final owner=(data['ownerId']??'').toString().trim();
        final skill=(data['skill']??'').toString().trim();
        if(owner.isEmpty || skill.isEmpty) continue;
        final list = verifiedByOwner.putIfAbsent(owner, () => []); if (!list.contains(skill)) list.add(skill);
      }
      lastVerifiedDoc=page.docs.last;
      if(page.docs.length<pageSize) break;
    } while(lastVerifiedDoc!=null);
    final candidates=<AurenTalentCandidate>[];
    for(final doc in profileDocs){
      final d=doc.data(); final owner=doc.reference.parent.parent?.id ?? '';
      if(owner.isEmpty || owner==excludeUid) continue;
      final skills=_strings(d['skills']), verifiedSkills=verifiedByOwner[owner] ?? const <String>[], interests=_strings(d['interests']), goals=_strings(d['goals']), languages=_strings(d['languages']), services=_strings(d['services']);
      final hay=_normalize([d['headline']??'',d['bio']??'',...verifiedSkills,...interests,...goals,...languages,...services].join(' '));
      final terms=q.split(' ').where((x)=>x.length>1).toSet();
      final hits=terms.where(hay.contains).length;
      if(hits==0) continue;
      final reasons=<String>[];
      if(terms.any((t)=>verifiedSkills.any((s)=>_normalize(s).contains(t)))) reasons.add('مهارات موثقة مطابقة');
      if(terms.any((t)=>services.any((s)=>_normalize(s).contains(t)))) reasons.add('خدمات مناسبة');
      if(terms.any((t)=>goals.any((g)=>_normalize(g).contains(t)))) reasons.add('أهداف متقاربة');
      if(terms.any((t)=>interests.any((i)=>_normalize(i).contains(t)))) reasons.add('اهتمامات مشتركة');
      final score=(45 + hits*12 + (d['mode']=='professional'?5:0)).clamp(0,100).toInt();
      candidates.add(AurenTalentCandidate(uid:owner,mode:d['mode']?.toString()??'personal',headline:d['headline']?.toString()??'',bio:d['bio']?.toString()??'',skills:skills,verifiedSkills:verifiedSkills,interests:interests,goals:goals,languages:languages,services:services,showContact:d['showContact']==true,score:score,reasons:reasons.isEmpty?const ['مطابقة نصية']:reasons));
    }
    candidates.sort((a,b)=>b.score.compareTo(a.score));
    return candidates.take(limit.clamp(1,100).toInt()).toList();
  }

  Future<List<AurenTalentCandidate>> matchOpportunity({
    required String title,
    required String description,
    required List<String> skills,
    String? excludeUid,
    int limit = 20,
  }) async {
    final requiredSkills = skills
        .map(_normalize)
        .where((x) => x.isNotEmpty)
        .toSet();
    if (requiredSkills.isEmpty) return const [];

    // Do not route opportunity matching through the text-search scout:
    // a strong verified candidate can be missed simply because their profile
    // text does not contain the opportunity title/description wording.
    // Page discoverable profiles instead of imposing a hard global cap.
    final profileDocs =
        <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    const profilePageSize = 500;
    DocumentSnapshot<Map<String, dynamic>>? lastProfileDoc;
    do {
      Query<Map<String, dynamic>> profileQuery = _db
          .collectionGroup('profile_modes')
          .where('discoverable', isEqualTo: true)
          .limit(profilePageSize);
      if (lastProfileDoc != null) {
        profileQuery = profileQuery.startAfterDocument(lastProfileDoc!);
      }
      final page = await profileQuery.get();
      if (page.docs.isEmpty) break;
      profileDocs.addAll(page.docs);
      lastProfileDoc = page.docs.last;
      if (page.docs.length < profilePageSize) break;
    } while (lastProfileDoc != null);

    final verifiedByOwner = <String, List<String>>{};
    const pageSize = 500;
    DocumentSnapshot<Map<String, dynamic>>? lastVerifiedDoc;
    do {
      Query<Map<String, dynamic>> query = _db
          .collection('talent_skill_graph')
          .where('verified', isEqualTo: true)
          .limit(pageSize);
      if (lastVerifiedDoc != null) {
        query = query.startAfterDocument(lastVerifiedDoc!);
      }
      final page = await query.get();
      if (page.docs.isEmpty) break;
      for (final skillDoc in page.docs) {
        final data = skillDoc.data();
        final owner = (data['ownerId'] ?? '').toString().trim();
        final skill = (data['skill'] ?? '').toString().trim();
        if (owner.isEmpty || skill.isEmpty) continue;
        final list = verifiedByOwner.putIfAbsent(owner, () => []); if (!list.contains(skill)) list.add(skill);
      }
      lastVerifiedDoc = page.docs.last;
      if (page.docs.length < pageSize) break;
    } while (lastVerifiedDoc != null);

    final matches = <AurenTalentCandidate>[];
    final seenOwners = <String>{};
    for (final doc in profileDocs) {
      final d = doc.data();
      final owner = doc.reference.parent.parent?.id ?? '';
      if (owner.isEmpty || owner == excludeUid || !seenOwners.add(owner)) continue;

      final verifiedSkills = verifiedByOwner[owner] ?? const <String>[];
      final matched = verifiedSkills
          .where((skill) => requiredSkills.contains(_normalize(skill)))
          .toList();
      if (matched.isEmpty) continue;

      final skillsList = _strings(d['skills']);
      final interests = _strings(d['interests']);
      final goals = _strings(d['goals']);
      final languages = _strings(d['languages']);
      final services = _strings(d['services']);
      final score = (60 + matched.length * 15).clamp(0, 100).toInt();

      matches.add(AurenTalentCandidate(
        uid: owner,
        mode: d['mode']?.toString() ?? 'personal',
        headline: d['headline']?.toString() ?? '',
        bio: d['bio']?.toString() ?? '',
        skills: skillsList,
        verifiedSkills: verifiedSkills,
        interests: interests,
        goals: goals,
        languages: languages,
        services: services,
        showContact: d['showContact'] == true,
        score: score,
        reasons: const ['مهارات موثقة مطابقة للفرصة'],
      ));
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.take(limit.clamp(1, 100).toInt()).toList();
  }

  Future<void> inviteToOpportunity({required String ownerId,required String talentUid,required String opportunityId,required String opportunityTitle}) async {
    final cleanOwnerId=ownerId.trim(), cleanTalentUid=talentUid.trim(), cleanOpportunityId=opportunityId.trim(), cleanTitle=opportunityTitle.trim();
    if(cleanOwnerId.isEmpty || cleanTalentUid.isEmpty || cleanOpportunityId.isEmpty) throw ArgumentError('بيانات الدعوة غير مكتملة.');
    if(cleanOwnerId.length > 128 || cleanTalentUid.length > 128 || cleanOpportunityId.length > 128) throw ArgumentError('معرّف الدعوة طويل جدًا.');
    if(cleanOwnerId == cleanTalentUid) throw ArgumentError('لا يمكن دعوة نفسك.');
    if(cleanTitle.isEmpty || cleanTitle.length > 200) throw ArgumentError('عنوان الفرصة غير صالح.');
    final ref=_db.collection('opportunity_invitations').doc(cleanOpportunityId + '_' + cleanTalentUid);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) {
        throw StateError('تم إرسال دعوة لهذه الموهبة لهذه الفرصة من قبل.');
      }
      transaction.set(ref, {
        'ownerId': cleanOwnerId,
        'talentUid': cleanTalentUid,
        'opportunityId': cleanOpportunityId,
        'opportunityTitle': cleanTitle,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> respondToInvitation({required String invitationId,required String talentUid,required String status}) async {
    final cleanInvitationId=invitationId.trim(), cleanTalentUid=talentUid.trim();
    if(cleanInvitationId.isEmpty || cleanInvitationId.length > 256 || cleanTalentUid.isEmpty || cleanTalentUid.length > 128) throw ArgumentError('بيانات الرد غير صالحة.');
    if(!['accepted','declined'].contains(status)) throw ArgumentError('حالة الدعوة غير صالحة.');
    final ref=_db.collection('opportunity_invitations').doc(cleanInvitationId);
    final snap=await ref.get();
    final data=snap.data();
    if(data==null || data['talentUid'] != cleanTalentUid) throw StateError('الدعوة غير موجودة.');
    if(data['status'] != 'pending') throw StateError('تمت معالجة هذه الدعوة بالفعل.');
    await ref.update({'status':status,'updatedAt':FieldValue.serverTimestamp()});
  }

  Stream<List<Map<String,dynamic>>> watchInvitations(String talentUid) {
    final uid = talentUid.trim();
    if (uid.isEmpty) return Stream.value(const <Map<String, dynamic>>[]);

    return _db
        .collection('opportunity_invitations')
        .where('talentUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) {
          final items = s.docs
              .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
              .toList();
          items.sort((a, b) {
            final aTime = a['createdAt'];
            final bTime = b['createdAt'];
            int millis(dynamic value) {
              if (value is Timestamp) return value.millisecondsSinceEpoch;
              if (value is DateTime) return value.millisecondsSinceEpoch;
              return 0;
            }
            return millis(bTime).compareTo(millis(aTime));
          });
          return items;
        });
  }

  List<String> _strings(dynamic v)=>v is List?v.whereType<String>().map((x)=>x.trim()).where((x)=>x.isNotEmpty).take(30).toList():const [];
  String _normalize(String value){var s=value.toLowerCase();const marks='\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0670';for(final r in marks.runes){s=s.replaceAll(String.fromCharCode(r),'');}return s.replaceAll('أ','ا').replaceAll('إ','ا').replaceAll('آ','ا').replaceAll('ى','ي').replaceAll('ة','ه').replaceAll('ـ',' ').replaceAll(RegExp(r'\s+'),' ').trim();}
}