import 'package:cloud_firestore/cloud_firestore.dart';

class AurenRandomCall {
  final String id, callerUid, calleeUid, kind, status;
  final Map<String, dynamic>? offer, answer;
  const AurenRandomCall({required this.id,required this.callerUid,required this.calleeUid,required this.kind,required this.status,this.offer,this.answer});
  factory AurenRandomCall.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){final x=d.data()??{};return AurenRandomCall(id:d.id,callerUid:x['callerUid'] as String? ?? '',calleeUid:x['calleeUid'] as String? ?? '',kind:x['kind'] as String? ?? 'video',status:x['status'] as String? ?? 'ringing',offer:(x['offer'] as Map?)?.cast<String,dynamic>(),answer:(x['answer'] as Map?)?.cast<String,dynamic>());}
}
class AurenRandomCallService {
  final FirebaseFirestore db;
  AurenRandomCallService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> get _calls=>db.collection('random_calls');
  Future<String> create({required String callerUid,required String calleeUid,required String kind})async{final ref=_calls.doc();await ref.set({'callerUid':callerUid,'calleeUid':calleeUid,'kind':kind,'status':'ringing','createdAt':FieldValue.serverTimestamp()});return ref.id;}
  Stream<AurenRandomCall?> watch(String id)=>_calls.doc(id).snapshots().map((d)=>d.exists?AurenRandomCall.fromDoc(d):null);
  Stream<QuerySnapshot<Map<String,dynamic>>> watchCandidates(String id)=>_calls.doc(id).collection('candidates').snapshots();
  Future<void> setOffer(String id,Map<String,dynamic> offer)=>_calls.doc(id).update({'offer':offer});
  Future<void> answer(String id,Map<String,dynamic> answer)=>_calls.doc(id).update({'answer':answer,'status':'connected'});
  Future<void> addCandidate(String id,{required String senderUid,required RTCandidate candidate})=>_calls.doc(id).collection('candidates').add({'senderUid':senderUid,'candidate':candidate.candidate,'sdpMid':candidate.sdpMid,'sdpMLineIndex':candidate.sdpMLineIndex,'createdAt':FieldValue.serverTimestamp()});
  Future<void> end(String id,String uid)=>_calls.doc(id).update({'status':'ended','endedBy':uid,'endedAt':FieldValue.serverTimestamp()});
}
class RTCandidate { final String? candidate; final String? sdpMid; final int? sdpMLineIndex; const RTCandidate({this.candidate,this.sdpMid,this.sdpMLineIndex}); }
