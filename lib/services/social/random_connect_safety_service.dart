import 'package:cloud_firestore/cloud_firestore.dart';

class AurenRandomConnectSafetyService {
  final FirebaseFirestore _db;
  AurenRandomConnectSafetyService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String,dynamic>> get _blocks => _db.collection('random_connect_blocks');
  CollectionReference<Map<String,dynamic>> get _reports => _db.collection('random_connect_reports');

  Future<void> block({required String uid, required String blockedUid}) async {
    if (uid.isEmpty || blockedUid.isEmpty || uid == blockedUid) return;
    await _blocks.doc('${uid}_$blockedUid').set({'uid':uid,'blockedUid':blockedUid,'createdAt':FieldValue.serverTimestamp()});
  }

  Future<void> unblock({required String uid, required String blockedUid}) => _blocks.doc('${uid}_$blockedUid').delete();

  Future<bool> isBlockedEitherWay(String uid, String otherUid) async {
    final a=await _blocks.doc('${uid}_$otherUid').get();
    if(a.exists)return true;
    final b=await _blocks.doc('${otherUid}_$uid').get();
    return b.exists;
  }

  Stream<Set<String>> watchBlocked(String uid) => _blocks.where('uid',isEqualTo:uid).snapshots().map((s)=>s.docs.map((d)=>d.data()['blockedUid'] as String? ?? '').where((x)=>x.isNotEmpty).toSet());

  Future<void> reportUser({required String reporterUid, required String reportedUid, required String reason}) async {
    if(reporterUid.isEmpty || reportedUid.isEmpty || reporterUid==reportedUid) return;
    await _reports.add({'reporterUid':reporterUid,'reportedUid':reportedUid,'reason':reason.trim().isEmpty?'other':reason.trim(),'createdAt':FieldValue.serverTimestamp(),'source':'random_connect'});
  }
}
