import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _localNotificationsReady = false;
  bool _pushNotificationsReady = false;
  StreamSubscription<String>? _fcmTokenSubscription;
  StreamSubscription<RemoteMessage>? _fcmMessageSubscription;
  StreamSubscription<RemoteMessage>? _fcmOpenedSubscription;
  bool _notificationRoutingReady = false;
  String? _pendingNotificationRoomId;
  void Function(String roomId)? _notificationRoomHandler;

  void setNotificationRoomHandler(void Function(String roomId) handler) {
    _notificationRoomHandler = handler;
    final pending = _pendingNotificationRoomId;
    if (pending != null && pending.isNotEmpty) {
      _pendingNotificationRoomId = null;
      scheduleMicrotask(() => handler(pending));
    }
  }

  Future<void> initializeNotificationRouting() async {
    await initializeNotifications();
    if (_notificationRoutingReady) return;
    final messaging = FirebaseMessaging.instance;
    _fcmOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedRemoteMessage);
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleOpenedRemoteMessage(initial);
    _notificationRoutingReady = true;
  }

  void _handleOpenedRemoteMessage(RemoteMessage message) {
    final roomId = (message.data['roomId'] as String?)?.trim();
    if (roomId == null || roomId.isEmpty) return;
    _openNotificationRoom(roomId);
  }

  void _handleLocalNotificationTap(String? payload) {
    final roomId = payload?.trim();
    if (roomId == null || roomId.isEmpty) return;
    _openNotificationRoom(roomId);
  }

  void _openNotificationRoom(String roomId) {
    final handler = _notificationRoomHandler;
    if (handler == null) {
      _pendingNotificationRoomId = roomId;
      return;
    }
    handler(roomId);
  }


  Future<void> initializeNotifications() async {
    if (_localNotificationsReady) return;
    const settings = InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'));
    await _localNotifications.initialize(settings, onDidReceiveNotificationResponse: (response) => _handleLocalNotificationTap(response.payload));
    final android = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel('auren_watch_together_chat', 'Watch Together Chat', description: 'رسائل المشاهدة الجماعية', importance: Importance.high));
    await android?.createNotificationChannel(const AndroidNotificationChannel('auren_watch_together_activity', 'Watch Together Activity', description: 'تنبيهات نشاط غرف المشاهدة', importance: Importance.defaultImportance));
    await android?.requestNotificationsPermission();
    _localNotificationsReady = true;
  }

  Future<void> initializePushNotifications() async {
    await initializeNotificationRouting();
    if (_pushNotificationsReady) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await _saveFcmToken(await messaging.getToken());
    await _fcmTokenSubscription?.cancel();
    _fcmTokenSubscription = messaging.onTokenRefresh.listen(_saveFcmToken);
    await _fcmMessageSubscription?.cancel();
    _fcmMessageSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundPush);
    _pushNotificationsReady = true;
  }

  Future<void> _saveFcmToken(String? token) async {
    final user = FirebaseAuth.instance.currentUser;
    final value = token?.trim();
    if (user == null || value == null || value.isEmpty) return;
    await _db.collection('users').doc(user.uid).collection('watchTogetherTokens').doc(value).set({
      'token': value,
      'platform': 'android',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _handleForegroundPush(RemoteMessage message) async {
    final data = message.data;
    final roomId = (data['roomId'] as String?)?.trim();
    final type = (data['type'] as String?)?.trim();
    if (roomId == null || roomId.isEmpty) return;
    if (type == 'watch_together_chat') {
      final sender = (data['senderName'] as String?)?.trim();
      final body = (data['body'] as String?)?.trim();
      if (body == null || body.isEmpty) return;
      await notifyIncomingMessage(roomId: roomId, sender: sender?.isNotEmpty == true ? sender! : 'AUREN', message: body);
    } else if (type == 'watch_together_activity') {
      final title = (data['title'] as String?)?.trim();
      final body = (data['body'] as String?)?.trim();
      final eventId = (data['eventId'] as String?)?.trim() ?? message.messageId ?? DateTime.now().microsecondsSinceEpoch.toString();
      if (body == null || body.isEmpty) return;
      await notifyRoomActivity(roomId: roomId, title: title?.isNotEmpty == true ? title! : 'Watch Together', body: body, eventId: eventId);
    }
  }

  Future<void> disposePushNotifications() async {
    await _fcmTokenSubscription?.cancel();
    await _fcmMessageSubscription?.cancel();
    _fcmTokenSubscription = null;
    _fcmMessageSubscription = null;
    _pushNotificationsReady = false;
  }

  Future<void> disposeNotificationRouting() async {
    await _fcmOpenedSubscription?.cancel();
    _fcmOpenedSubscription = null;
    _notificationRoutingReady = false;
    _notificationRoomHandler = null;
  }

  Future<void> notifyIncomingMessage({required String roomId, required String sender, required String message}) async {
    await initializeNotifications();
    const details = NotificationDetails(android: AndroidNotificationDetails('auren_watch_together_chat', 'Watch Together Chat', channelDescription: 'رسائل المشاهدة الجماعية', importance: Importance.high, priority: Priority.high));
    final body = message.length > 120 ? '${message.substring(0, 117)}...' : message;
    await _localNotifications.show(roomId.hashCode & 0x7fffffff, 'رسالة من $sender', body, details, payload: roomId);
  }

  Future<void> notifyRoomActivity({required String roomId, required String title, required String body, required String eventId}) async {
    await initializeNotifications();
    const details = NotificationDetails(android: AndroidNotificationDetails('auren_watch_together_activity', 'Watch Together Activity', channelDescription: 'تنبيهات نشاط غرف المشاهدة', importance: Importance.defaultImportance, priority: Priority.defaultPriority));
    final id = eventId.hashCode & 0x7fffffff;
    await _localNotifications.show(id, title, body, details, payload: roomId);
  }

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
    await _db.runTransaction((tx) async {final s=await tx.get(ref);if(!s.exists)throw StateError('Room unavailable');final d=s.data()!;final m=List<String>.from(d['memberIds'] as List? ?? const []);if(!m.contains(u.uid)){if(m.length>=8)throw StateError('Room full');m.add(u.uid);tx.update(ref,{'memberIds':m,'status':'ready','updatedAt':FieldValue.serverTimestamp()});}});
    final room = AurenTvWatchTogetherRoom.fromDoc(await ref.get());
    try { await notifyActivity(room.id, type: 'joined'); await sendSystemMessage(room.id, '${_displayName()} انضم للمشاهدة'); } catch (_) {}
    return room;
  }
  Future<AurenTvWatchTogetherRoom?> getRoom(String roomId) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return null;
    final snap = await _rooms.doc(roomId).get();
    if (!snap.exists) return null;
    final room = AurenTvWatchTogetherRoom.fromDoc(snap);
    if (!room.memberIds.contains(u.uid)) return null;
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
      'displayName': _displayName(),
      'lastSeen':FieldValue.serverTimestamp(),
    },SetOptions(merge:true));
  }

  Stream<QuerySnapshot<Map<String,dynamic>>> presence(String roomId) =>
      _presence(roomId).snapshots();

  Stream<QuerySnapshot<Map<String,dynamic>>> messages(String roomId) =>
      _rooms.doc(roomId).collection('messages').orderBy('createdAt', descending: true).limit(100).snapshots();

  CollectionReference<Map<String,dynamic>> _readReceipts(String roomId) =>
      _rooms.doc(roomId).collection('read_receipts');

  Stream<QuerySnapshot<Map<String,dynamic>>> readReceipts(String roomId) =>
      _readReceipts(roomId).snapshots();

  Future<void> markMessagesRead(String roomId, {String? lastMessageId}) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final room = await _rooms.doc(roomId).get();
    if (!room.exists) return;
    final members = List<String>.from(room.data()?['memberIds'] as List? ?? const []);
    if (!members.contains(u.uid)) return;
    final ref = _readReceipts(roomId).doc(u.uid);
    await ref.set({
      'uid': u.uid,
      'lastMessageId': lastMessageId ?? '',
      'lastReadAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

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

  Stream<QuerySnapshot<Map<String,dynamic>>> typing(String roomId) =>
      _rooms.doc(roomId).collection('typing').snapshots();

  Future<void> setTyping(String roomId, bool isTyping) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final room = await _rooms.doc(roomId).get();
    if (!room.exists) return;
    final members = List<String>.from(room.data()?['memberIds'] as List? ?? const []);
    if (!members.contains(u.uid)) return;
    await _rooms.doc(roomId).collection('typing').doc(u.uid).set({
      'uid': u.uid,
      'typing': isTyping,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearTyping(String roomId) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    try { await _rooms.doc(roomId).collection('typing').doc(u.uid).delete(); } catch (_) {}
  }

  String _displayName() {
    final u = FirebaseAuth.instance.currentUser;
    final name = u?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name.length > 80 ? name.substring(0, 80) : name;
    final email = u?.email?.trim();
    if (email != null && email.isNotEmpty) return email.length > 80 ? email.substring(0, 80) : email;
    return 'عضو';
  }

  Future<void> sendSystemMessage(String roomId, String text) async {
    final u = FirebaseAuth.instance.currentUser;
    final value = text.trim();
    if (u == null || value.isEmpty || value.length > 160) return;
    final room = await _rooms.doc(roomId).get();
    if (!room.exists) return;
    final members = List<String>.from(room.data()?['memberIds'] as List? ?? const []);
    if (!members.contains(u.uid)) return;
    await _rooms.doc(roomId).collection('messages').add({
      'type': 'system',
      'senderUid': u.uid,
      'senderName': 'AUREN',
      'text': value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendMessage(String roomId, String text) async {
    final u = FirebaseAuth.instance.currentUser;
    final value = text.trim();
    if (u == null || value.isEmpty || value.length > 500) return;
    final room = await _rooms.doc(roomId).get();
    if (!room.exists) return;
    final members = List<String>.from(room.data()?['memberIds'] as List? ?? const []);
    if (!members.contains(u.uid)) return;
    await _rooms.doc(roomId).collection('messages').add({
      'type': 'user',
      'senderUid': u.uid,
      'senderName': _displayName(),
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
  Future<void> leave(String roomId) async {final u=FirebaseAuth.instance.currentUser;if(u==null)return;final name=_displayName();await heartbeat(roomId,online:false);try { await sendSystemMessage(roomId, '$name غادر المشاهدة'); } catch (_) {}final ref=_rooms.doc(roomId);await _db.runTransaction((tx)async{final s=await tx.get(ref);if(!s.exists)return;final d=s.data()!;final m=List<String>.from(d['memberIds'] as List? ?? const []);m.remove(u.uid);if(u.uid==d['hostUid']){if(m.length>1){final next=m.firstWhere((id)=>id!=u.uid);tx.update(ref,{'hostUid':next,'memberIds':m..remove(u.uid),'status':'ready','updatedAt':FieldValue.serverTimestamp()});}else{tx.delete(ref);}return;}if(m.isEmpty){tx.delete(ref);return;}tx.update(ref,{'memberIds':m,'status':m.length>1?'ready':'waiting','updatedAt':FieldValue.serverTimestamp()});});}
}