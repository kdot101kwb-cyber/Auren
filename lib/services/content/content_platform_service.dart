import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/entertainment.dart';

class AurenChannel {
  final String id, ownerId, name, description, avatarUrl;
  final int subscribers;
  const AurenChannel({required this.id,required this.ownerId,required this.name,required this.description,required this.avatarUrl,required this.subscribers});
  factory AurenChannel.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){final x=d.data()??{};return AurenChannel(id:d.id,ownerId:(x['ownerId']??'').toString(),name:(x['name']??'').toString(),description:(x['description']??'').toString(),avatarUrl:(x['avatarUrl']??'').toString(),subscribers:(x['subscribers'] as num?)?.toInt()??0);}
}
class AurenContentPlatformService {
  AurenContentPlatformService._(); static final instance=AurenContentPlatformService._(); final _db=FirebaseFirestore.instance;
  Stream<List<AurenEntertainmentItem>> watchPublicVideos({String query=''}) => _db.collection('entertainment_items').where('visibility',isEqualTo:'public').limit(100).snapshots().map((s){ final q=query.trim().toLowerCase(); return s.docs.map((d)=>AurenEntertainmentItem.fromMap(d.id,d.data())).where((x)=>x.isVideo && x.mediaUrl.isNotEmpty && (q.isEmpty || ('${x.title} ${x.description} ${x.type}'.toLowerCase().contains(q)))).take(50).toList(); });
  Stream<List<AurenChannel>> watchChannels() => _db.collection('content_channels').where('public',isEqualTo:true).limit(100).snapshots().map((s)=>s.docs.map(AurenChannel.fromDoc).toList());

  Future<void> ensureStarterChannels(String uid) async {
    if (uid.isEmpty) return;
    final existing = await _db.collection('content_channels').where('ownerId',isEqualTo:uid).limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final batch = _db.batch();
    final starters = <Map<String,String>>[
      {'name':'AUREN Discover','description':'اكتشاف ومحتوى متنوع من عالم AUREN'},
      {'name':'AUREN Learn','description':'تعلم عملي، مهارات، معرفة وتجارب'},
      {'name':'AUREN Creators','description':'محتوى صناع ومبدعين من مختلف المجالات'},
      {'name':'AUREN World','description':'ثقافة، سفر، ألعاب وتجارب تفاعلية'},
      {'name':'AUREN Stories','description':'قصص، أفكار وسلاسل أصلية داخل AUREN'},
    ];
    for (final s in starters) { final r=_db.collection('content_channels').doc(); batch.set(r,{'ownerId':uid,'name':s['name'],'description':s['description'],'avatarUrl':'','subscribers':0,'public':true,'createdAt':FieldValue.serverTimestamp()}); }
    await batch.commit();
  }
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