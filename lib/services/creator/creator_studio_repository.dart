import 'package:cloud_firestore/cloud_firestore.dart';

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
