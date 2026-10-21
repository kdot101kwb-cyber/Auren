import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community_casework_models.dart';
class AurenCommunityCaseworkService {
 final FirebaseFirestore db; final FirebaseAuth auth;
 AurenCommunityCaseworkService({FirebaseFirestore? db,FirebaseAuth? auth}):db=db??FirebaseFirestore.instance,auth=auth??FirebaseAuth.instance;
 String get uid=>auth.currentUser?.uid??(throw StateError('Sign in required'));
 Stream<List<AurenCaseReport>> watchQueue()=>db.collection('reports').orderBy('createdAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map(AurenCaseReport.fromDoc).toList());
 Future<void> review({required String id,required String status,required String note}) async {
 final n=note.trim();if(id.trim().isEmpty||!const {'under_review','resolved','rejected'}.contains(status)||n.length>1000||(status!='under_review'&&n.isEmpty))throw ArgumentError('Invalid review decision.');
 final r=db.collection('reports').doc(id.trim()),e=db.collection('community_governance_events').doc();final old=await r.get();if(!old.exists)throw StateError('Report not found.');final from=old.data()?['status'] as String? ?? '';if(!const {'open','under_review'}.contains(from)||from==status)throw StateError('Report is not reviewable.');
 final b=db.batch();b.set(r,{'status':status,'moderatedBy':uid,'moderatedAt':FieldValue.serverTimestamp(),'moderationNote':n},SetOptions(merge:true));b.set(e,{'entityType':'report','entityId':id.trim(),'actorUid':uid,'fromStatus':from,'toStatus':status,'note':n,'createdAt':FieldValue.serverTimestamp()});await b.commit();
 }
}
