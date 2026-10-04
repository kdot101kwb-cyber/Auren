import 'package:cloud_firestore/cloud_firestore.dart';

class AurenDecisionOption {
  final String title, detail; final List<String> pros, cons; final int fit;
  const AurenDecisionOption({required this.title,required this.detail,required this.pros,required this.cons,required this.fit});
}
class AurenDecisionRoom {
  final String question,recommendation,reasoning; final List<AurenDecisionOption> options; final DateTime createdAt;
  const AurenDecisionRoom({required this.question,required this.options,required this.recommendation,required this.reasoning,required this.createdAt});
  Map<String,dynamic> toMap()=>{'question':question,'options':options.map((o)=>{'title':o.title,'detail':o.detail,'pros':o.pros,'cons':o.cons,'fit':o.fit}).toList(),'recommendation':recommendation,'reasoning':reasoning,'createdAt':Timestamp.fromDate(createdAt.toUtc())};
}
class DecisionRoomService {
 final FirebaseFirestore _db;
 DecisionRoomService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
 Future<AurenDecisionRoom> build(String uid,{required String question,required List<String> options}) async {
  final id=uid.trim(),q=question.trim(),opts=options.map((x)=>x.trim()).where((x)=>x.isNotEmpty).take(5).toList();
  if(id.isEmpty)throw ArgumentError('uid is required');if(q.isEmpty)throw ArgumentError('question is required');if(opts.length<2)throw ArgumentError('at least two options are required');
  final goals=await _db.collection('users').doc(id).collection('goals').get();
  final active=goals.docs.where((d)=>(d.data()['status']?.toString()??'active')=='active').toList();
  final goal=active.isEmpty?'لا يوجد هدف نشط':(active.first.data()['title']?.toString()??'هدف حالي');
  final scored=opts.asMap().entries.map((e){final fit=(78-e.key*6).clamp(45,90).toInt();return AurenDecisionOption(title:e.value,detail:'قارن هذا الخيار مع سؤالك وهدفك الحالي: '+goal+'.',pros:const ['يمكن مقارنته مباشرة','يمكن تحويله إلى خطوات'],cons:const ['قد تحتاج معلومات إضافية'],fit:fit);}).toList();
  final best=scored.reduce((a,b)=>a.fit>=b.fit?a:b);
  final room=AurenDecisionRoom(question:q,options:scored,recommendation:best.title,reasoning:'مقارنة أولية فقط. القرار النهائي ليك؛ راجع القيود والمعلومات الناقصة قبل التنفيذ.',createdAt:DateTime.now().toUtc());
  await _db.collection('users').doc(id).collection('decision_rooms').doc('current').set(room.toMap());return room;
 }
 Stream<DocumentSnapshot<Map<String,dynamic>>> watch(String uid)=>_db.collection('users').doc(uid).collection('decision_rooms').doc('current').snapshots();
}