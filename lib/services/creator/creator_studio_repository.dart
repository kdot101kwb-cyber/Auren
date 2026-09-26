import 'package:cloud_firestore/cloud_firestore.dart';

class AurenCreatorEarning {
  final String id, creatorUid, supporterUid, currency, type, status;
  final int amountMinor;
  final DateTime createdAt;
  const AurenCreatorEarning({required this.id,required this.creatorUid,required this.supporterUid,required this.currency,required this.type,required this.status,required this.amountMinor,required this.createdAt});
  factory AurenCreatorEarning.fromMap(String id, Map<String,dynamic> m) => AurenCreatorEarning(
    id:id, creatorUid:(m['creatorUid']??'').toString(), supporterUid:(m['supporterUid']??'').toString(),
    currency:(m['currency']??'').toString(), type:(m['type']??'').toString(), status:(m['status']??'pending_settlement').toString(),
    amountMinor:(m['amountMinor'] as num?)?.toInt()??0,
    createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : m['createdAt'] is DateTime ? m['createdAt'] as DateTime : DateTime.now(),
  );
}

class AurenCreatorStats {
  final int posts;
  final int likes;
  final int mediaPosts;

  const AurenCreatorStats({
    required this.posts,
    required this.likes,
    required this.mediaPosts,
  });

  int get totalContent => posts;
}

class AurenCreatorStudioRepository {
  final FirebaseFirestore _db;

  AurenCreatorStudioRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _posts => _db.collection('posts');

  Future<AurenCreatorStats> loadStats(String uid) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty || cleanUid.length > 128) {
      throw ArgumentError('Invalid creator uid.');
    }
    final snap = await _posts.where('authorId', isEqualTo: cleanUid).limit(100).get();
    var likes = 0;
    var mediaPosts = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      likes += (data['likes'] as num?)?.toInt() ?? 0;
      if ((data['mediaUrl'] ?? '').toString().trim().isNotEmpty) mediaPosts++;
    }
    return AurenCreatorStats(posts: snap.size, likes: likes, mediaPosts: mediaPosts);
  }

  Stream<List<Map<String, dynamic>>> watchRecentPosts(String uid) {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return const Stream.empty();
    return _posts.where('authorId', isEqualTo: cleanUid).limit(50).snapshots().map((snap) {
      final items = snap.docs.map((d) => <String, dynamic>{'id': d.id, ...d.data()}).toList();
      items.sort((a, b) => (b['createdAt'] ?? '').toString().compareTo((a['createdAt'] ?? '').toString()));
      return items;
    });
  }

  Future<String> publish({
    required String uid,
    required String text,
    String mediaUrl = '',
    String mediaType = 'none',
    String contentType = 'creator',
  }) async {
    final cleanUid = uid.trim();
    final cleanText = text.trim();
    final cleanMedia = mediaUrl.trim();
    if (cleanUid.isEmpty || cleanUid.length > 128) throw ArgumentError('Invalid creator uid.');
    if (cleanText.isEmpty || cleanText.length > 4000) throw ArgumentError('Creator post text must be 1–4000 characters.');
    if (cleanMedia.length > 2000) throw ArgumentError('Media URL is too long.');
    if (!{'none', 'image', 'video', 'audio'}.contains(mediaType)) throw ArgumentError('Unsupported media type.');

    final ref = _posts.doc();
    await ref.set({
      'authorId': cleanUid,
      'text': cleanText,
      'mediaUrl': cleanMedia,
      'mediaType': cleanMedia.isEmpty ? 'none' : mediaType,
      'contentType': contentType.trim().isEmpty ? 'creator' : contentType.trim(),
      'contextLabel': 'Creator',
      'actionLabel': '',
      'communityId': '',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'likes': 0,
      'comments': 0,
      'searchText': cleanText.toLowerCase(),
    });
    return ref.id;
  }

  Future<String> createCreatorSupportRequest({required String creatorUid,required int amountMinor,required String currency,required String message})async{
    final u=creatorUid.trim(),supporter=supporterUid.trim(),m=message.trim(),cur=currency.trim().toUpperCase();
    if(u.isEmpty||u.length>128||supporter.isEmpty||supporter.length>128)throw ArgumentError('Invalid user id.');
  if(u==supporter)throw ArgumentError('Creator and supporter must be different.');
    if(amountMinor<=0||amountMinor>100000000)throw ArgumentError('Invalid support amount.');
    if(cur.length!=3)throw ArgumentError('Currency must be 3 letters.');
    if(m.length>500)throw ArgumentError('Support message is too long.');
    final ref=_db.collection('creator_support_requests').doc();
    await ref.set({'creatorUid':u,'supporterUid':supporter,'amountMinor':amountMinor,'currency':cur,'message':m,'status':'pending','createdAt':FieldValue.serverTimestamp()});
    return ref.id;
  }

  Stream<List<AurenCreatorEarning>> watchEarnings(String creatorUid) {
    final uid = creatorUid.trim();
    if (uid.isEmpty || uid.length > 128) return const Stream.empty();
    return _db.collection('creator_earnings')
        .where('creatorUid', isEqualTo: uid)
        .limit(100)
        .snapshots()
        .map((snap) {
          final items = snap.docs.map((d) => AurenCreatorEarning.fromMap(d.id, d.data())).toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }
  Future<void> delete(String uid, String postId) async {
    final cleanUid = uid.trim();
    final cleanPostId = postId.trim();
    if (cleanUid.isEmpty || cleanPostId.isEmpty) throw ArgumentError('Creator and post id are required.');
    final ref = _posts.doc(cleanPostId);
    final snap = await ref.get();
    if (!snap.exists || snap.data()?['authorId'] != cleanUid) throw StateError('You can only delete your own creator content.');
    await ref.delete();
  }
}
