import 'package:cloud_firestore/cloud_firestore.dart';

class AurenRandomCall {
  final String id, callerUid, calleeUid, kind, status;
  final Map<String,dynamic>? offer, answer;
  AurenRandomCall({required this.id,required this.callerUid,required this.calleeUid,required this.kind,required this.status,this.offer,this.answer});
  factory AurenRandomCall.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){final x=d.data()??{};return AurenRandomCall(id:d.id,callerUid:x['callerUid']??'',calleeUid:x['calleeUid']??'',kind:x['kind']??'video',status:x['status']??'ringing',offer:(x['offer'] as Map?)?.cast<String,dynamic>(),answer:(x['answer'] as Map?)?.cast<String,dynamic>());}
}
class AurenRandomCallService{
 final FirebaseFirestore db; AurenRandomCallService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
 Future<String> create({required String callerUid,required String calleeUid,required String kind,required Map<String,dynamic> offer})async{final r=db.collection('random_calls').doc();await r.set({'callerUid':callerUid,'calleeUid':calleeUid,'kind':kind,'status':'ringing','offer':offer,'createdAt':FieldValue.serverTimestamp()});return r.id;}
 Stream<AurenRandomCall?> watch(String id)=>db.collection('random_calls').doc(id).snapshots().map((d)=>d.exists?AurenRandomCall.fromDoc(d):null);
 Future<void> answer(String id,Map<String,dynamic> answer)=>db.collection('random_calls').doc(id).update({'answer':answer,'status':'connected'});
 Future<void> end(String id,String uid)=>db.collection('random_calls').doc(id).update({'status':'ended','endedBy':uid,'endedAt':FieldValue.serverTimestamp()});
 CollectionReference<Map<String,dynamic>> candidates(String id)=>db.collection('random_calls').doc(id).collection('candidates');
}