import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AurenTvWatchTogetherRoom {
  final String id,title,inviteCode,status;
  final String? hostUid;
  final List<String> memberIds;
  final String? channelId,channelName;
  final double positionSeconds;
  final bool isPlaying;
  const AurenTvWatchTogetherRoom({required this.id,required this.title,required this.inviteCode,required this.memberIds,required this.hostUid,required this.channelId,required this.channelName,required this.positionSeconds,required this.isPlaying,required this.status});
  factory AurenTvWatchTogetherRoom.fromDoc(DocumentSnapshot<Map<String,dynamic>> doc){
    final d=doc.data()??const <String,dynamic>{};
    return AurenTvWatchTogetherRoom(id:doc.id,title:d['title'] as String? ?? 'AUREN TV Room',inviteCode:d['inviteCode'] as String? ?? '',hostUid:d['hostUid'] as String?,memberIds:List<String>.from(d['memberIds'] as List? ?? const []),channelId:d['channelId'] as String?,channelName:d['channelName'] as String?,positionSeconds:(d['positionSeconds'] as num?)?.toDouble()??0,isPlaying:d['isPlaying'] as bool?false,status:d['status'] as String?'waiting');
  }
}
class AurenTvWatchTogetherService {
  static final instance=AurenTvWatchTogetherService._(); AurenTvWatchTogetherService._();
  final _db=FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> get _rooms=>_db.collection('watch_together_rooms');
  String _code(){const chars='ABCDEFGHJKLMNPQRSTUVWXYZ23456789';var n=DateTime.now().microsecondsSinceEpoch;var o='';for(var i=0;i<6;i++){o+=chars[n%chars.length];n=n~/chars.length;}return o;}
  Future<AurenTvWatchTogetherRoom?> create({required String title,required String channelId,required String channelName}) async {
    final u=FirebaseAuth.instance.currentUser;if(u==null)return null;final ref=_rooms.doc();
    await ref.set({'hostUid':u.uid,'memberIds':[u.uid],'inviteCode':_code(),'title':title.trim().isEmpty?'AUREN TV Room':title.trim(),'channelId':channelId,'channelName':channelName,'positionSeconds':0,'isPlaying':false,'status':'waiting','updatedAt':FieldValue.serverTimestamp()});
    final s=await ref.get();return s.exists?AurenTvWatchTogetherRoom.fromDoc(s):null;
  }
  Future<AurenTvWatchTogetherRoom?> join(String code) async {
    final u=FirebaseAuth.instance.currentUser;if(u==null)return null;
    final q=await _rooms.where('inviteCode',isEqualTo:code.trim().toUpperCase()).limit(1).get();if(q.docs.isEmpty)return null;final ref=q.docs.first.reference;
    await _db.runTransaction((tx) async {final s=await tx.get(ref);if(!s.exists)throw StateError('Room unavailable');final d=s.data()!;final m=List<String>.from(d['memberIds'] as List?const []);if(!m.contains(u.uid)){if(m.length>=8)throw StateError('Room full');m.add(u.uid);tx.update(ref,{'memberIds':m,'status':'ready','updatedAt':FieldValue.serverTimestamp()});}});
    final room = AurenTvWatchTogetherRoom.fromDoc(await ref.get());
    try { await notifyActivity(room.id, type: 'joined'); } catch (_) {}
    return room;
  }
  Stream<AurenTvWatchTogetherRoom> watch(String roomId)=>_rooms.doc(roomId).snapshots().where((s)=>s.exists).map(AurenTvWatchTogetherRoom.fromDoc);

  CollectionReference<Map<String,dynamic>> _presence(String roomId) =>
      _rooms.doc(roomId).collection('presence');

  Future<void> heartbeat(String roomId,{bool online=true}) async {
    final u=FirebaseAuth.instance.currentUser;
    if(u==null)return;
    final room=await _rooms.doc(roomId).get();
    if(!room.exists)return;
    final members=List<String>.from(room.data()?['memberIds'] as List? ?? const []);
    if(!members.contains(u.uid))return;
    await _presence(roomId).doc(u.uid).set({
      'uid':u.uid,
      'online':online,
      'lastSeen':FieldValue.serverTimestamp(),
    },SetOptions(merge:true));
  }

  Stream<QuerySnapshot<Map<String,dynamic>>> presence(String roomId) =>
      _presence(roomId).snapshots();

  Stream<QuerySnapshot<Map<String,dynamic>>> messages(String roomId) =>
      _rooms.doc(roomId).collection('messages').orderBy('createdAt', descending: true).limit(100).snapshots();

  Future<void> sendReaction(String roomId, String emoji) async {
    final u = FirebaseAuth.instance.currentUser;
    final value = emoji.trim();
    if (u == null || value.isEmpty || value.length > 8) return;
    final room = await _rooms.doc(roomId).get();
    if (!room.exists) return;
    final members = List<String>.from(room.data()?['memberIds'] as List? ?? const []);
    if (!members.contains(u.uid)) return;
    await _rooms.doc(roomId).collection('reactions').add({
      'senderUid': u.uid,
      'emoji': value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String,dynamic>>> reactions(String roomId) =>
      _rooms.doc(roomId).collection('reactions').orderBy('createdAt', descending: true).limit(50).snapshots();

  Future<void> sendMessage(String roomId, String text) async {
    final u = FirebaseAuth.instance.currentUser;
    final value = text.trim();
    if (u == null || value.isEmpty || value.length > 500) return;
    final room = await _rooms.doc(roomId).get();
    if (!room.exists) return;
    final members = List<String>.from(room.data()?['memberIds'] as List? ?? const []);
    if (!members.contains(u.uid)) return;
    await _rooms.doc(roomId).collection('messages').add({
      'senderUid': u.uid,
      'text': value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String,dynamic>>> activity(String roomId) =>
      _rooms.doc(roomId).collection('activity').orderBy('createdAt', descending: true).limit(20).snapshots();

  Future<void> notifyActivity(String roomId,{required String type}) async {
    final u=FirebaseAuth.instance.currentUser;
    if(u==null)return;
    final room=await _rooms.doc(roomId).get();
    if(!room.exists)return;
    final members=List<String>.from(room.data()?['memberIds'] as List? ?? const []);
    if(!members.contains(u.uid))return;
    await _rooms.doc(roomId).collection('activity').add({
      'type':type,
      'actorUid':u.uid,
      'createdAt':FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isHost(String roomId) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return false;
    final s = await _rooms.doc(roomId).get();
    if (!s.exists) return false;
    return s.data()?['hostUid'] == u.uid;
  }

  Future<bool> sync(String roomId,{String? channelId,String? channelName,double? positionSeconds,bool? isPlaying}) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return false;
    final ref = _rooms.doc(roomId);
    final s = await ref.get();
    if (!s.exists) return false;
    final data = s.data()!;
    // Playback and channel state are host-authoritative.
    if (data['hostUid'] != u.uid) return false;
    final d = <String,dynamic>{'updatedAt':FieldValue.serverTimestamp()};
    if (channelId != null) d['channelId']=channelId;
    if (channelName != null) d['channelName']=channelName;
    if (positionSeconds != null) d['positionSeconds']=positionSeconds.clamp(0,86400);
    if (isPlaying != null) d['isPlaying']=isPlaying;
    await ref.update(d);
    return true;
  }

  Future<void> close(String roomId) async {final u=FirebaseAuth.instance.currentUser;if(u==null)return;final ref=_rooms.doc(roomId);final s=await ref.get();if(!s.exists)return;final d=s.data()!;if(d['hostUid']!=u.uid)throw StateError('Only the host can close the room');await ref.update({'status':'closed','updatedAt':FieldValue.serverTimestamp()});await ref.delete();}
  Future<void> leave(String roomId) async {final u=FirebaseAuth.instance.currentUser;if(u==null)return;await heartbeat(roomId,online:false);final ref=_rooms.doc(roomId);await _db.runTransaction((tx)async{final s=await tx.get(ref);if(!s.exists)return;final d=s.data()!;final m=List<String>.from(d['memberIds'] as List?const []);m.remove(u.uid);if(u.uid==d['hostUid']){if(m.length>1){final next=m.firstWhere((id)=>id!=u.uid);tx.update(ref,{'hostUid':next,'memberIds':m..remove(u.uid),'status':'ready','updatedAt':FieldValue.serverTimestamp()});}else{tx.delete(ref);}return;}if(m.isEmpty){tx.delete(ref);return;}tx.update(ref,{'memberIds':m,'status':m.length>1?'ready':'waiting','updatedAt':FieldValue.serverTimestamp()});});}
}