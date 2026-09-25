import 'package:cloud_firestore/cloud_firestore.dart';

class AurenTrustSignal { final String id,type,label; final DateTime? createdAt; const AurenTrustSignal({required this.id,required this.type,required this.label,this.createdAt}); factory AurenTrustSignal.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){final m=d.data()??{};return AurenTrustSignal(id:d.id,type:m['type'] as String? ?? 'signal',label:m['label'] as String? ?? '',createdAt:(m['createdAt'] as Timestamp?)?.toDate());}}
class AurenTrustGraphService {
 final FirebaseFirestore _db; AurenTrustGraphService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
 CollectionReference<Map<String,dynamic>> _signals(String uid)=>_db.collection('users').doc(uid).collection('trust_signals');
 Stream<List<AurenTrustSignal>> watchMySignals(String uid)=>_signals(uid).orderBy('createdAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map(AurenTrustSignal.fromDoc).toList());
 Future<void> addSignal({required String uid,required String type,required String label})async{final clean=label.trim();if(clean.isEmpty||clean.length>240)throw ArgumentError('Signal label must be 1–240 characters.');if(!['identity_verified','successful_connection','positive_review','completed_collaboration'].contains(type))throw ArgumentError('Unsupported trust signal.');await _signals(uid).add({'type':type,'label':clean,'createdAt':FieldValue.serverTimestamp()});}
 Future<void> removeSignal(String uid,String signalId)=>_signals(uid).doc(signalId).delete();
 Stream<List<AurenTrustSignal>> watchPublicSignals(String uid)=>_signals(uid).orderBy('createdAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map(AurenTrustSignal.fromDoc).toList());
 int descriptiveCount(List<AurenTrustSignal> s,String type)=>s.where((x)=>x.type==type).length;
}
