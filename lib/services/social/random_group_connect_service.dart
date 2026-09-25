import 'package:cloud_firestore/cloud_firestore.dart';
import '../messaging/conversation_repository.dart';

class AurenRandomGroupConnectService {
  final FirebaseFirestore _db;
  AurenRandomGroupConnectService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _c => _db.collection('random_group_connect');

  Future<String> join({required String uid, required String country, required String language, required String interest, required String goal, int groupSize = 4}) async {
    final size = groupSize.clamp(3, 8);
    final ref = _c.doc();
    await ref.set({'uid': uid, 'country': country.trim(), 'language': language.trim(), 'interest': interest.trim(), 'goal': goal.trim(), 'groupSize': size, 'status': 'waiting', 'createdAt': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Stream<List<Map<String, dynamic>>> watch({required String uid, required String language, int groupSize = 4}) => _c.where('status', isEqualTo: 'waiting').where('groupSize', isEqualTo: groupSize.clamp(3, 8)).limit(40).snapshots().map((s) => s.docs.where((d) => d.data()['uid'] != uid).map((d) => {'id': d.id, ...d.data()}).toList());

  Future<String> formGroup({required String requestId, required String uid, required List<String> memberUids}) async {
    final members = {...memberUids, uid}.toList();
    if (members.length < 3 || members.length > 8) throw StateError('Group size must be between 3 and 8.');
    final groupRef = _db.collection('random_groups').doc();
    await _db.runTransaction((tx) async {
      final req = await tx.get(_c.doc(requestId));
      if (!req.exists || req.data()?['status'] != 'waiting') throw StateError('This group request is no longer available.');
      tx.set(groupRef, {'memberUids': members, 'size': members.length, 'status': 'active', 'createdAt': FieldValue.serverTimestamp()});
      tx.update(_c.doc(requestId), {'status': 'grouped', 'groupId': groupRef.id, 'matchedAt': FieldValue.serverTimestamp()});
    });
    return groupRef.id;
  }

  Future<String> createMessengerGroup({required String groupId, required String uid, required String title}) async { final groupRef=_db.collection('random_groups').doc(groupId); final snap=await groupRef.get(); final data=snap.data(); if(!snap.exists||data==null) throw StateError('Group not found.'); final members=List<String>.from(data['memberUids'] as List? ?? const []); if(!members.contains(uid)) throw StateError('Only a group member can open the chat.'); final existing=data['conversationId'] as String?; if(existing!=null&&existing.isNotEmpty)return existing; final conversation=await ConversationRepository(firestore:_db).createGroup(uid:uid,title:title,memberIds:members); await _db.runTransaction((tx) async { final latest=await tx.get(groupRef); final latestId=latest.data()?['conversationId'] as String?; if(latestId==null||latestId.isEmpty)tx.update(groupRef,{'conversationId':conversation.id,'chatReady':true}); }); return conversation.id; }

  Future<void> cancel(String uid, String requestId) async { final ref = _c.doc(requestId); final snap = await ref.get(); if (snap.exists && snap.data()?['uid'] == uid) await ref.update({'status': 'cancelled'}); }
}
