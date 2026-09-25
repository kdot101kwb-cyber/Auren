import 'package:cloud_firestore/cloud_firestore.dart';

class AurenCreatorDraft {
  final String id, title, caption, format, audience, status;
  final List<String> ideas, steps;
  final DateTime? updatedAt;
  const AurenCreatorDraft({required this.id,required this.title,required this.caption,required this.format,required this.audience,required this.status,required this.ideas,required this.steps,this.updatedAt});
  factory AurenCreatorDraft.fromMap(String id, Map<String,dynamic> d)=>AurenCreatorDraft(
    id:id,title:d['title']?.toString()??'',caption:d['caption']?.toString()??'',format:d['format']?.toString()??'Short',
    audience:d['audience']?.toString()??'',status:d['status']?.toString()??'draft',
    ideas:(d['ideas'] is List)?List<String>.from((d['ideas'] as List).map((e)=>e.toString())):const [],
    steps:(d['steps'] is List)?List<String>.from((d['steps'] as List).map((e)=>e.toString())):const [],
    updatedAt:(d['updatedAt'] as dynamic)?.toDate());
}

class CreatorStudioService {
  final FirebaseFirestore _db;
  CreatorStudioService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> _drafts(String uid)=>_db.collection('users').doc(uid).collection('creator_drafts');

  Stream<List<AurenCreatorDraft>> watch(String uid)=>_drafts(uid).orderBy('updatedAt',descending:true).limit(50).snapshots()
    .map((s)=>s.docs.map((d)=>AurenCreatorDraft.fromMap(d.id,d.data())).toList());

  Future<void> saveDraft({required String uid,required String title,required String caption,required String format,required String audience}) async {
    final ref=_drafts(uid).doc();
    final topic=title.trim().isEmpty?'فكرة محتوى جديدة':title.trim();
    await ref.set({
      'title':topic,'caption':caption.trim(),'format':format,'audience':audience.trim(),
      'status':'draft',
      'ideas':[
        'Hook واضح خلال أول 3 ثوانٍ',
        'معلومة أو لحظة أساسية مرتبطة بالموضوع',
        'دعوة بسيطة للتفاعل أو المتابعة',
      ],
      'steps':['حدد الفكرة والجمهور','جهز النص واللقطات','راجع الحقوق والجودة','انشر بعد المراجعة'],
      'updatedAt':FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus(String uid,String id,String status)=>_drafts(uid).doc(id).update({'status':status,'updatedAt':FieldValue.serverTimestamp()});
  Future<void> delete(String uid,String id)=>_drafts(uid).doc(id).delete();
}
