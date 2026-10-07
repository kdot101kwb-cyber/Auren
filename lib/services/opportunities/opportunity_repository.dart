import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/opportunity.dart';

class AurenOpportunityApplication {
  final String id, opportunityId, ownerId, applicantId, title, note, status; final double matchScore; final List<String> matchedVerifiedSkills;
  final DateTime? createdAt, updatedAt;
  const AurenOpportunityApplication({required this.id,required this.opportunityId,required this.ownerId,required this.applicantId,required this.title,required this.note,required this.status,required this.matchScore,required this.matchedVerifiedSkills,this.createdAt,this.updatedAt});
  factory AurenOpportunityApplication.fromMap(String id, Map<String,dynamic> d) => AurenOpportunityApplication(id:id,opportunityId:d['opportunityId']?.toString()??'',ownerId:d['ownerId']?.toString()??'',applicantId:d['applicantId']?.toString()??'',title:d['title']?.toString()??'',note:d['note']?.toString()??'',status:d['status']?.toString()??'pending',matchScore:(d['matchScore'] as num?)?.toDouble()??0.0,matchedVerifiedSkills:(d['matchedVerifiedSkills'] as List?)?.map((e)=>e.toString()).toList()??const <String>[],createdAt:d['createdAt'] is Timestamp?(d['createdAt'] as Timestamp).toDate():null,updatedAt:d['updatedAt'] is Timestamp?(d['updatedAt'] as Timestamp).toDate():null);
}

class OpportunityRepository{final FirebaseFirestore db;OpportunityRepository({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
Stream<List<AurenOpportunity>> watchOpen({String query='',String type='All'}){final q=query.trim().toLowerCase();return db.collection('opportunities').where('status',isEqualTo:'open').limit(100).snapshots().map((s){final list=s.docs.map((d)=>AurenOpportunity.fromMap(d.id,d.data())).where((o)=>type=='All'||o.type==type).where((o)=>q.isEmpty||('${o.title} ${o.description} ${o.category} ${o.city} ${o.country} ${o.skills.join(' ')}').toLowerCase().contains(q)).toList();list.sort((a,b)=>(b.createdAt??DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.createdAt??DateTime.fromMillisecondsSinceEpoch(0)));return list;});}
Stream<List<AurenOpportunity>> watchSaved(String uid) => db.collection('users').doc(uid).collection('savedOpportunities').orderBy('createdAt', descending: true).limit(100).snapshots().map((s) => s.docs.map((d) => AurenOpportunity.fromMap(d.id, {
  'ownerId': '',
  'title': d.data()['title'] ?? '',
  'description': '',
  'type': d.data()['type'] ?? 'opportunity',
  'category': d.data()['category'] ?? '',
  'city': d.data()['city'] ?? '',
  'country': d.data()['country'] ?? '',
  'status': 'open',
  'skills': const <String>[],
  'createdAt': d.data()['createdAt'],
})).toList());

Stream<bool> watchInterested(String uid, String opportunityId) => db.collection('users').doc(uid).collection('savedOpportunities').doc(opportunityId).snapshots().map((d) => d.exists);

Future<bool> hasApplied(String uid, String opportunityId) async => (await db.collection('users').doc(uid).collection('opportunityApplications').doc(opportunityId).get()).exists;

Stream<List<AurenOpportunityApplication>> watchMyApplications(String uid) => db.collection('users').doc(uid).collection('opportunityApplications').orderBy('createdAt', descending:true).limit(100).snapshots().map((s)=>s.docs.map((d)=>AurenOpportunityApplication.fromMap(d.id,d.data())).toList());

Stream<List<AurenOpportunityApplication>> watchReceived(String ownerId) => db.collectionGroup('opportunityApplications').where('ownerId',isEqualTo:ownerId).limit(100).snapshots().map((s)=>s.docs.map((d)=>AurenOpportunityApplication.fromMap(d.id,d.data())).toList());

Future<List<Map<String, dynamic>>> findVerifiedSkillMatches(String uid) async {
  if (uid.trim().isEmpty) return const <Map<String, dynamic>>[];

  final verifiedSnap = await db.collection('talent_skill_graph')
      .where('ownerId', isEqualTo: uid)
      .where('verified', isEqualTo: true)
      .limit(50)
      .get();

  final verifiedSkills = verifiedSnap.docs
      .map((d) => (d.data()['skill'] ?? '').toString().trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toSet();
  if (verifiedSkills.isEmpty) return const <Map<String, dynamic>>[];

  final opportunitySnap = await db.collection('opportunities')
      .where('status', isEqualTo: 'open')
      .limit(100)
      .get();

  final matches = <Map<String, dynamic>>[];
  for (final doc in opportunitySnap.docs) {
    final opportunity = AurenOpportunity.fromMap(doc.id, doc.data());
    if (opportunity.ownerId == uid) continue;

    final matched = opportunity.skills
        .map((s) => s.trim().toLowerCase())
        .where(verifiedSkills.contains)
        .toSet()
        .toList();
    if (matched.isEmpty) continue;

    final score = opportunity.skills.isEmpty
        ? 0.0
        : (matched.length / opportunity.skills.length).clamp(0.0, 1.0);
    matches.add({
      'opportunity': opportunity,
      'matchedSkills': matched,
      'score': score,
    });
  }

  matches.sort((a, b) =>
      (b['score'] as double).compareTo(a['score'] as double));
  return matches.take(20).toList();
}

Stream<List<Map<String, dynamic>>> watchApplicationNotifications(String uid) =>
    db.collection('opportunity_application_notifications')
      .where('recipientUid', isEqualTo: uid)
      .limit(100)
      .snapshots()
      .map((s) {
        final list = s.docs.map((d) => <String, dynamic>{
          'id': d.id,
          ...d.data(),
        }).toList();
        list.sort((a, b) {
          final at = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bt = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bt.compareTo(at);
        });
        return list;
      });

Future<void> markApplicationNotificationRead(String uid, String notificationId) async {
  if (uid.trim().isEmpty || notificationId.trim().isEmpty) return;
  final ref = db.collection('opportunity_application_notifications').doc(notificationId);
  final snap = await ref.get();
  if (!snap.exists || snap.data()?['recipientUid'] != uid) {
    throw StateError('الإشعار غير متاح.');
  }
  await ref.update({'read': true});
}

Future<void> updateApplicationStatus({required String ownerId, required String applicantId,required String opportunityId,required String status}) async {
  if(!['accepted','rejected'].contains(status)) throw ArgumentError('حالة الطلب غير صالحة');
  if (ownerId.trim().isEmpty || applicantId.trim().isEmpty || opportunityId.trim().isEmpty) {
    throw ArgumentError('بيانات الطلب غير صالحة');
  }
  final opportunityRef = db.collection('opportunities').doc(opportunityId);
  final applicationRef = db.collection('users').doc(applicantId).collection('opportunityApplications').doc(opportunityId);
  final opportunitySnap = await opportunityRef.get();
  if (!opportunitySnap.exists || opportunitySnap.data()?['ownerId']?.toString() != ownerId) {
    throw StateError('ليس لديك صلاحية تعديل هذا الطلب.');
  }
  final applicationSnap = await applicationRef.get();
  if (!applicationSnap.exists || applicationSnap.data()?['ownerId']?.toString() != ownerId) {
    throw StateError('الطلب غير متاح أو لا يتبع فرصتك.');
  }
  await applicationRef.update({'status':status,'updatedAt':FieldValue.serverTimestamp()});
  await db.collection('opportunity_application_notifications').add({
    'recipientUid': applicantId,
    'opportunityId': opportunityId,
    'title': status == 'accepted' ? 'تم قبول طلبك' : 'تم رفض طلبك',
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
    'read': false,
  });
}

Future<void> apply({required String uid, required AurenOpportunity opportunity, required String note}) async {
  if (uid.trim().isEmpty || opportunity.id.trim().isEmpty) throw ArgumentError('بيانات التقديم غير صالحة');
  if (uid == opportunity.ownerId) throw StateError('لا يمكنك التقديم على فرصتك الخاصة.');
  if (opportunity.status != 'open') throw StateError('هذه الفرصة لم تعد مفتوحة.');
  final cleanNote = note.trim();
  if (cleanNote.length > 2000) throw ArgumentError('الملاحظة طويلة جداً');

  final verifiedSnap = await db.collection('talent_skill_graph')
      .where('ownerId', isEqualTo: uid)
      .where('verified', isEqualTo: true)
      .limit(30)
      .get();
  final verifiedSkills = verifiedSnap.docs
      .map((d) => (d.data()['skill'] ?? '').toString().trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toSet();
  final matchedSkills = opportunity.skills
      .map((s) => s.trim().toLowerCase())
      .where((s) => verifiedSkills.contains(s))
      .toSet()
      .toList();
  final matchScore = opportunity.skills.isEmpty
      ? 0.0
      : (matchedSkills.length / opportunity.skills.length).clamp(0.0, 1.0);

  final ref = db.collection('users').doc(uid).collection('opportunityApplications').doc(opportunity.id);
  final existing = await ref.get();
  if (existing.exists) throw StateError('سبق أن تقدمت لهذه الفرصة.');
  await ref.set({
    'opportunityId': opportunity.id,
    'ownerId': opportunity.ownerId,
    'applicantId': uid,
    'title': opportunity.title,
    'note': cleanNote,
    'matchScore': matchScore,
    'matchedVerifiedSkills': matchedSkills,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  if (opportunity.ownerId.isNotEmpty) {
    await db.collection('opportunity_application_notifications').add({
      'recipientUid': opportunity.ownerId,
      'applicantUid': uid,
      'opportunityId': opportunity.id,
      'title': 'تقديم جديد على فرصتك',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}

Future<void> toggleInterest({required String uid, required String opportunityId, required bool interested, required Map<String, dynamic> snapshot}) async {
  if (uid.trim().isEmpty || opportunityId.trim().isEmpty) throw ArgumentError('بيانات الفرصة غير صالحة');
  final ref = db.collection('users').doc(uid).collection('savedOpportunities').doc(opportunityId);
  if (interested) {
    await ref.delete();
    return;
  }
  await ref.set({
    'opportunityId': opportunityId,
    'title': snapshot['title']?.toString() ?? '',
    'type': snapshot['type']?.toString() ?? 'opportunity',
    'category': snapshot['category']?.toString() ?? '',
    'city': snapshot['city']?.toString() ?? '',
    'country': snapshot['country']?.toString() ?? '',
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Future<String> create({required String ownerId,required String title,required String description,required String type,required String category,required String city,required String country,required List<String> skills})async{final ref=db.collection('opportunities').doc();await ref.set({'ownerId':ownerId,'title':title.trim(),'description':description.trim(),'type':type,'category':category.trim(),'city':city.trim(),'country':country.trim(),'skills':skills.map((e)=>e.trim().toLowerCase()).where((e)=>e.isNotEmpty).take(20).toList(),'status':'open','visibility':'public','createdAt':FieldValue.serverTimestamp()});return ref.id;}}