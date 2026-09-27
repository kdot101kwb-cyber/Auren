import 'package:cloud_firestore/cloud_firestore.dart';

class AurenChannel {
  final String id, ownerId, name, description, avatarUrl;
  final int subscribers;
  const AurenChannel({required this.id,required this.ownerId,required this.name,required this.description,required this.avatarUrl,required this.subscribers});
  factory AurenChannel.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){final x=d.data()??{};return AurenChannel(id:d.id,ownerId:(x['ownerId']??'').toString(),name:(x['name']??'').toString(),description:(x['description']??'').toString(),avatarUrl:(x['avatarUrl']??'').toString(),subscribers:(x['subscribers'] as num?)?.toInt()??0);}
}
class AurenContentPlatformService {
  AurenContentPlatformService._(); static final instance=AurenContentPlatformService._(); final _db=FirebaseFirestore.instance;
  Stream<List<AurenChannel>> watchChannels() => _db.collection('content_channels').where('public',isEqualTo:true).limit(50).snapshots().map((s)=>s.docs.map(AurenChannel.fromDoc).toList());
  Future<String> createChannel({required String uid,required String name,required String description}) async {
    if(uid.isEmpty||name.trim().isEmpty||name.trim().length>100||description.length>1000) throw ArgumentError('بيانات القناة غير صالحة.');
    final r=_db.collection('content_channels').doc();
    await r.set({'ownerId':uid,'name':name.trim(),'description':description.trim(),'avatarUrl':'','subscribers':0,'public':true,'createdAt':FieldValue.serverTimestamp()}); return r.id;
  }
  Future<void> subscribe(String uid,String channelId,bool value) async {
    final r=_db.collection('content_channels').doc(channelId).collection('subscribers').doc(uid);
    if(value) await r.set({'uid':uid,'createdAt':FieldValue.serverTimestamp()}); else await r.delete();
  }
  Stream<bool> watchSubscribed(String uid,String channelId)=>_db.collection('content_channels').doc(channelId).collection('subscribers').doc(uid).snapshots().map((d)=>d.exists);
}