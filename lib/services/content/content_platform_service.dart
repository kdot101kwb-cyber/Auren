import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/entertainment.dart';

class AurenChannel {
  final String id, ownerId, name, description, avatarUrl;
  final int subscribers;
  const AurenChannel({required this.id, required this.ownerId, required this.name, required this.description, required this.avatarUrl, required this.subscribers});
  factory AurenChannel.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final x=d.data()??{};
    return AurenChannel(id:d.id,ownerId:(x['ownerId']??'').toString(),name:(x['name']??'').toString(),description:(x['description']??'').toString(),avatarUrl:(x['avatarUrl']??'').toString(),subscribers:(x['subscribers'] as num?)?.toInt()??0);
  }
}

class AurenContentPlatformService {
  AurenContentPlatformService._();
  static final instance=AurenContentPlatformService._();
  final _db=FirebaseFirestore.instance;

  Stream<List<AurenEntertainmentItem>> watchPublicVideos({String query=''}) =>
      _db.collection('entertainment_items').where('visibility',isEqualTo:'public').limit(100).snapshots().map((s){
        final q=query.trim().toLowerCase();
        return s.docs.map((d)=>AurenEntertainmentItem.fromMap(d.id,d.data()))
          .where((x)=>x.isVideo && x.mediaUrl.isNotEmpty && (q.isEmpty || ('${x.title} ${x.description} ${x.type}'.toLowerCase().contains(q)))).take(50).toList();
      });

  Stream<List<AurenEntertainmentItem>> watchMyVideos(String uid) =>
      _db.collection('entertainment_items')
        .where('creatorId', isEqualTo: uid)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) => AurenEntertainmentItem.fromMap(d.id, d.data())).where((x) => x.isVideo).toList());

  Stream<List<AurenChannel>> watchChannels() =>
      _db.collection('content_channels').where('public',isEqualTo:true).limit(100).snapshots()
        .map((s)=>s.docs.map(AurenChannel.fromDoc).toList());

  Future<String> createChannel({required String uid,required String name,required String description}) async {
    if(uid.isEmpty||name.trim().isEmpty||name.trim().length>100||description.trim().length>1000) throw ArgumentError('بيانات القناة غير صالحة.');
    final r=_db.collection('content_channels').doc();
    await r.set({'ownerId':uid,'name':name.trim(),'description':description.trim(),'avatarUrl':'','subscribers':0,'public':true,'createdAt':FieldValue.serverTimestamp()});
    return r.id;
  }

  Future<String> publishVideo({required String uid,required String channelId,required String title,required String description,required String mediaUrl,String imageUrl='',String type='Video'}) async {
    final cleanTitle=title.trim(), cleanDescription=description.trim(), cleanUrl=mediaUrl.trim();
    if(uid.isEmpty||channelId.isEmpty||cleanTitle.isEmpty||cleanTitle.length>160||cleanDescription.length>3000||cleanUrl.isEmpty||cleanUrl.length>2000) throw ArgumentError('بيانات الفيديو غير صالحة.');
    final channel=await _db.collection('content_channels').doc(channelId).get();
    if(!channel.exists || channel.data()?['ownerId']!=uid) throw StateError('القناة لا تخص هذا الحساب.');
    final ref=_db.collection('entertainment_items').doc();
    await ref.set({'title':cleanTitle,'description':cleanDescription,'mediaUrl':cleanUrl,'mediaKind':'video','imageUrl':imageUrl.trim(),'type':type.trim().isEmpty?'Video':type.trim(),'creatorId':uid,'channelId':channelId,'visibility':'public','createdAt':FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> subscribe(String uid,String channelId,bool value) async {
    final r=_db.collection('content_channels').doc(channelId).collection('subscribers').doc(uid);
    if(value) await r.set({'uid':uid,'createdAt':FieldValue.serverTimestamp()}); else await r.delete();
  }

  Stream<bool> watchSubscribed(String uid,String channelId) =>
      _db.collection('content_channels').doc(channelId).collection('subscribers').doc(uid).snapshots().map((d)=>d.exists);
}
