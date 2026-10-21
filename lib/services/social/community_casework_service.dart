import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community_casework_models.dart';

class AurenCommunityCaseworkService {
  final FirebaseFirestore db; final FirebaseAuth auth;
  AurenCommunityCaseworkService({FirebaseFirestore? db,FirebaseAuth? auth}) : db=db??FirebaseFirestore.instance,auth=auth??FirebaseAuth.instance;
  String get uid=>auth.currentUser?.uid??(throw StateError('Sign in required'));
  Stream<List<AurenCaseReport>> watchQueue()=>db.collection('reports').orderBy('createdAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map(AurenCaseReport.fromDoc).toList());
}
