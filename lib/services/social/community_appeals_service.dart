import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community_casework_models.dart';
class AurenCommunityAppealsService {
 final FirebaseFirestore db; final FirebaseAuth auth;
 AurenCommunityAppealsService({FirebaseFirestore? db,FirebaseAuth? auth}):db=db??FirebaseFirestore.instance,auth=auth??FirebaseAuth.instance;
 String get uid=>auth.currentUser?.uid??(throw StateError('Sign in required'));
 CollectionReference<Map<String,dynamic>> get _appeals=>db.collection('community_case_appeals');
 Stream<List<AurenCaseAppeal>> watchPending()=>_appeals.where('status',isEqualTo:'pending').limit(50).snapshots().map((s)=>s.docs.map(AurenCaseAppeal.fromDoc).toList());
 Stream<List<AurenCaseAppeal>> watchMine()=>_appeals.where('appellantUid',isEqualTo:uid).limit(50).snapshots().map((s)=>s.docs.map(AurenCaseAppeal.fromDoc).toList());
 Future<String> submit({required String reportId,required String reason}) async {final id=reportId.trim(),text=reason.trim();if(id.isEmpty||text.isEmpty||text.length>1000)throw ArgumentError('Appeal reason must be 1–1000 characters.');final r=_appeals.doc('${id}__${uid}');await r.set({'reportId':id,'appellantUid':uid,'reason':text,'status':'pending','createdAt':FieldValue.serverTimestamp()});return r.id;}
}
