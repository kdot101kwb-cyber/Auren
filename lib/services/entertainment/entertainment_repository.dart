import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/entertainment.dart';

class EntertainmentRepository {
  final FirebaseFirestore db;
  EntertainmentRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AurenEntertainmentItem>> watchItems({String? type}) {
    Query<Map<String, dynamic>> q = db.collection('entertainment_items')
        .where('visibility', isEqualTo: 'public');
    if (type != null) q = q.where('type', isEqualTo: type);
    return q.limit(100).snapshots().map(
      (s) => s.docs.map((d) => AurenEntertainmentItem.fromMap(d.id, d.data())).toList(),
    );
  }

  Stream<List<AurenEntertainmentItem>> watchShorts({String? mood}) {
    return db.collection('entertainment_items')
        .where('visibility', isEqualTo: 'public')
        .where('type', isEqualTo: 'Short')
        .limit(100)
        .snapshots()
        .map((s) => _filterAndLimitShorts(s.docs, mood));
  }

  /// Local ranking avoids a composite Firestore index for visibility + type + moods.
  /// Signals are private to the user and only used to order the already-public feed.
  Stream<List<AurenEntertainmentItem>> watchPersonalizedShorts(
    String uid, {
    String? mood,
  }) {
    return db.collection('entertainment_items')
        .where('visibility', isEqualTo: 'public')
        .where('type', isEqualTo: 'Short')
        .limit(100)
        .snapshots()
        .asyncMap((s) async {
      var items = _filterAndLimitShorts(s.docs, mood, maxItems: 100);
      final signals = await db.collection('users').doc(uid)
          .collection('entertainmentSignals').get();

      final scores = <String, double>{};
      for (final d in signals.docs) {
        final data = d.data();
        final watchSeconds = (data['watchSeconds'] as num?)?.toDouble() ?? 0;
        final views = (data['views'] as num?)?.toDouble() ?? 0;
        final likes = (data['likes'] as num?)?.toDouble() ?? 0;
        final saves = (data['saves'] as num?)?.toDouble() ?? 0;
        final completions = (data['completions'] as num?)?.toDouble() ?? 0;
        final skips = (data['skips'] as num?)?.toDouble() ?? 0;

        var score = 0.0;
        score += watchSeconds * 0.025;
        score += views * 0.35;
        score += likes * 4.0;
        score += saves * 3.0;
        score += completions * 2.5;
        score -= skips * 1.5;
        if (mood != null && mood != 'تسلية' && data['mood'] == mood) {
          score += 3.0;
        }

        // A small novelty boost keeps the feed from becoming a replay of old items.
        if (views == 0 && likes == 0 && saves == 0) score += 6.0;
        scores[d.id] = score;
      }

      items.sort((a, b) {
        final scoreCompare = (scores[b.id] ?? 6.0).compareTo(scores[a.id] ?? 6.0);
        return scoreCompare != 0 ? scoreCompare : a.title.compareTo(b.title);
      });
      return items;
    });
  }

  List<AurenEntertainmentItem> _filterAndLimitShorts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String? mood, {
    int maxItems = 50,
  }) {
    final items = docs
        .map((d) => AurenEntertainmentItem.fromMap(d.id, d.data()))
        .where((i) => i.isVideo && i.mediaUrl.isNotEmpty)
        .where((i) => mood == null || mood.isEmpty || mood == 'تسلية' ||
            _itemMatchesMood(docs.firstWhere((d) => d.id == i.id).data(), mood))
        .take(maxItems)
        .toList();
    return items;
  }

  bool _itemMatchesMood(Map<String, dynamic> data, String mood) {
    final moods = data['moods'];
    return moods is List && moods.any((value) => value.toString() == mood);
  }

  Stream<AurenEntertainmentItem?> watchItem(String itemId) =>
      db.collection('entertainment_items').doc(itemId).snapshots().map((d) {
        final data = d.data();
        if (!d.exists || data == null || data['visibility'] != 'public') return null;
        return AurenEntertainmentItem.fromMap(d.id, data);
      });

  Stream<Set<String>> watchSavedIds(String uid) =>
      db.collection('users').doc(uid).collection('savedEntertainment').snapshots()
          .map((s) => s.docs.map((d) => d.id).toSet());

  Future<void> save(String uid, String itemId) =>
      db.collection('users').doc(uid).collection('savedEntertainment').doc(itemId).set({
        'itemId': itemId,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> unsave(String uid, String itemId) =>
      db.collection('users').doc(uid).collection('savedEntertainment').doc(itemId).delete();

  Future<void> toggleLike(String uid, String itemId, bool liked) =>
      toggleShortLike(uid, itemId, liked);

  Future<void> toggleShortLike(String uid, String itemId, bool liked) async {
    final ref = db.collection('entertainment_items').doc(itemId).collection('likes').doc(uid);
    if (liked) {
      await ref.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }

  Future<void> trackShortView(
    String uid,
    String itemId, {
    required int seconds,
    required bool completed,
    required String mood,
  }) =>
      db.collection('users').doc(uid).collection('entertainmentSignals').doc(itemId).set({
        'itemId': itemId,
        'lastViewedAt': FieldValue.serverTimestamp(),
        'watchSeconds': FieldValue.increment(seconds),
        'views': FieldValue.increment(1),
        'completions': FieldValue.increment(completed ? 1 : 0),
        'mood': mood,
      }, SetOptions(merge: true));

  Future<void> trackShortAction(
    String uid,
    String itemId, {
    required String action,
    required String mood,
  }) =>
      db.collection('users').doc(uid).collection('entertainmentSignals').doc(itemId).set({
        'itemId': itemId,
        'lastActionAt': FieldValue.serverTimestamp(),
        'mood': mood,
        'likes': FieldValue.increment(action == 'like' ? 1 : action == 'unlike' ? -1 : 0),
        'saves': FieldValue.increment(action == 'save' ? 1 : action == 'unsave' ? -1 : 0),
        'skips': FieldValue.increment(action == 'skip' ? 1 : 0),
      }, SetOptions(merge: true)).then((_) =>
          db.collection('users').doc(uid).collection('entertainmentSignals').doc(itemId)
              .collection('actions').add({
                'action': action,
                'mood': mood,
                'createdAt': FieldValue.serverTimestamp(),
              }));

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>> > watchShortComments(String itemId) =>
      db.collection('entertainment_items').doc(itemId).collection('comments')
          .orderBy('createdAt', descending: true).limit(100).snapshots().map((s) => s.docs);

  Future<void> addShortComment(String uid, String itemId, String text, {String mood = 'تسلية'}) async {
    final value = text.trim();
    if (value.isEmpty || value.length > 1000) return;
    await db.collection('entertainment_items').doc(itemId).collection('comments').add({
      'uid': uid,
      'text': value,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await trackShortAction(uid, itemId, action: 'comment', mood: mood);
  }

  Stream<bool> watchLiked(String uid, String itemId) =>
      db.collection('entertainment_items').doc(itemId).collection('likes').doc(uid)
          .snapshots().map((d) => d.exists);

  Stream<List<AurenEntertainmentItem>> watchSavedItems(String uid) =>
      db.collection('users').doc(uid).collection('savedEntertainment').snapshots()
          .asyncMap((s) async {
        final out = <AurenEntertainmentItem>[];
        for (final d in s.docs) {
          final item = await db.collection('entertainment_items').doc(d.id).get();
          if (item.exists && item.data()?['visibility'] == 'public') {
            out.add(AurenEntertainmentItem.fromMap(item.id, item.data()!));
          }
        }
        return out;
      });
}
