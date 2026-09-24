import 'package:cloud_firestore/cloud_firestore.dart';
class AurenWatchtowerAlert { final String title,detail; const AurenWatchtowerAlert(this.title,this.detail); }
class WatchtowerService {
 final FirebaseFirestore db; WatchtowerService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
 Future<List<AurenWatchtowerAlert>> scan(String uid) async {
  final out=<AurenWatchtowerAlert>[]; final g=await db.collection('users').doc(uid).collection('goals').limit(100).get();
  final active=g.docs.where((d)=>(d.data()['status']?.toString()??'active')=='active');
  if(active.isEmpty)out.add(const AurenWatchtowerAlert('لا يوجد هدف نشط','أضف هدفًا حتى يستطيع AUREN مراقبة التقدم.'));
  for(final d in active){final p=((d.data()['progress'] as num?)?.toInt()??0);if(p<25)out.add(AurenWatchtowerAlert('هدف يحتاج انتباه','الهدف '+(d.data()['title']??'هدف').toString()+' تقدمه '+p.toString()+'%.'));}
  try{final o=await db.collection('opportunities').where('visibility',isEqualTo:'public').limit(10).get();if(o.docs.isNotEmpty)out.add(AurenWatchtowerAlert('فرص متاحة','يوجد '+o.docs.length.toString()+' فرص عامة يمكن مراجعتها.'));}catch(_){}
  if(out.isEmpty)out.add(const AurenWatchtowerAlert('الوضع مستقر','لم يجد AUREN تنبيهًا واضحًا يحتاج تدخلاً الآن.'));
  return out;
 }
}