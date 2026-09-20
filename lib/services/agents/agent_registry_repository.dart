import 'package:cloud_firestore/cloud_firestore.dart';
class AurenAgentRegistryRepository {
 final FirebaseFirestore _db; AurenAgentRegistryRepository({FirebaseFirestore? db}):_db=db??FirebaseFirestore.instance;
 Stream<List<Map<String,dynamic>>> watchMine(String uid)=>_db.collection('users').doc(uid).collection('agents').orderBy('name').snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());
 Future<void> save({required String uid,required String agentId,required String name,required String version,required String status})=>_db.collection('users').doc(uid).collection('agents').doc(agentId).set({'name':name.trim(),'version':version.trim(),'status':status});
}
