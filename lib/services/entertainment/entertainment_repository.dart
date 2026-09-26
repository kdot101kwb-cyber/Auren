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

  Stream<List<AurenEntertainmentItem>> watchShorts({String? mood, Set<String> blockedCreatorIds = const {}}) {
    return db.collection('entertainment_items')
        .where('visibility', isEqualTo: 'public')
        .where('type', isEqualTo: 'Short')
        .limit(100)
        .snapshots()
        .map((s) => _filterAndLimitShorts(s.docs, mood)
            .where((i) => !blockedCreatorIds.contains(i.creatorId))
            .toList());
  }

  /// Local ranking avoids a composite Firestore index for visibility + type + moods.
  /// Signals are private to the user and only used to order the already-public feed.
  Stream<List<AurenEntertainmentItem>> watchPersonalizedShorts(
    String uid, {
    String? mood,
    Set<String> blockedCreatorIds = const {},
  }) {
    return db.collection('entertainment_items')
        .where('visibility', isEqualTo: 'public')
        .where('type', isEqualTo: 'Short')
        .limit(100)
        .snapshots()
        .asyncMap((s) async {
      var items = _filterAndLimitShorts(s.docs, mood, maxItems: 100)
          .where((i) => !blockedCreatorIds.contains(i.creatorId))
          .toList();
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


  /// Playback signals are private to the user and power Music/Audio recommendations.
  Future<void> trackMusicPlayback(
    String uid,
    String itemId, {
    required int seconds,
    required bool completed,
    required String contentType,
    bool countPlay = false,
  }) async {
    if (seconds <= 0 && !completed && !countPlay) return;
    await db.collection('users').doc(uid).collection('entertainmentSignals').doc(itemId).set({
      'itemId': itemId,
      'contentType': contentType,
      'lastPlayedAt': FieldValue.serverTimestamp(),
      'watchSeconds': FieldValue.increment(seconds),
      'plays': FieldValue.increment(countPlay ? 1 : 0),
      'completions': FieldValue.increment(completed ? 1 : 0),
    }, SetOptions(merge: true));
  }

  Future<void> trackMusicAction(
    String uid,
    String itemId, {
    required String action,
    required String contentType,
  }) async {
    final ref = db.collection('users').doc(uid).collection('entertainmentSignals').doc(itemId);
    await ref.set({
      'itemId': itemId,
      'contentType': contentType,
      'lastActionAt': FieldValue.serverTimestamp(),
      'likes': FieldValue.increment(action == 'like' ? 1 : action == 'unlike' ? -1 : 0),
      'saves': FieldValue.increment(action == 'save' ? 1 : action == 'unsave' ? -1 : 0),
      'skips': FieldValue.increment(action == 'skip' ? 1 : 0),
    }, SetOptions(merge: true));
    await ref.collection('actions').add({
      'action': action,
      'contentType': contentType,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchEntertainmentDrafts(String uid) {
    return db.collection('users').doc(uid).collection('entertainmentDrafts')
        .orderBy('updatedAt', descending: true).limit(20).snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<String> saveEntertainmentDraft(
    String uid, {
    required String mode,
    required String mood,
    required String length,
    required String idea,
  }) async {
    final ref = db.collection('users').doc(uid).collection('entertainmentDrafts').doc();
    await ref.set({
      'mode': mode,
      'mood': mood,
      'length': length,
      'idea': idea,
      'status': 'draft',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateEntertainmentDraft(
    String uid,
    String draftId, {
    required String mode,
    required String mood,
    required String length,
    required String idea,
  }) async {
    if (uid.isEmpty || draftId.isEmpty) return;
    await db.collection('users').doc(uid).collection('entertainmentDrafts').doc(draftId).update({
      'mode': mode,
      'mood': mood,
      'length': length,
      'idea': idea,
      'status': 'draft',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEntertainmentDraft(String uid, String draftId) {
    return db.collection('users').doc(uid).collection('entertainmentDrafts').doc(draftId).delete();
  }

  Stream<List<Map<String, dynamic>>> watchEntertainmentCreationJobs(String uid) {
    return db.collection('users').doc(uid).collection('entertainmentCreationJobs')
        .orderBy('updatedAt', descending: true).limit(20).snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<String> createEntertainmentJob(
    String uid, {
    required String draftId,
    required String mode,
    required String mood,
    required String length,
    required String idea,
  }) async {
    final ref = db.collection('users').doc(uid).collection('entertainmentCreationJobs').doc();
    await ref.set({
      'draftId': draftId,
      'mode': mode,
      'mood': mood,
      'length': length,
      'idea': idea,
      'status': 'planning',
      'provider': 'auren_ai',
      'progress': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateEntertainmentJobStatus(
    String uid,
    String jobId, {
    required String status,
    required int progress,
  }) async {
    if (uid.isEmpty || jobId.isEmpty) return;
    await db.collection('users').doc(uid).collection('entertainmentCreationJobs').doc(jobId).update({
      'status': status,
      'progress': progress.clamp(0, 100),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchContinueWatching(String uid) {
    return db.collection('users').doc(uid).collection('continueWatching')
        .orderBy('updatedAt', descending: true).limit(20).snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> saveWatchProgress(String uid, AurenEntertainmentItem item, Duration position, Duration duration) async {
    if (uid.isEmpty || item.id.isEmpty) return;
    final total = duration.inSeconds;
    final seconds = position.inSeconds.clamp(0, total > 0 ? total : 1);
    final completed = total > 0 && seconds >= (total * 0.95).round();
    final ref = db.collection('users').doc(uid).collection('continueWatching').doc(item.id);
    if (completed) {
      await ref.delete();
      return;
    }
    await ref.set({
      'itemId': item.id,
      'title': item.title,
      'type': item.type,
      'imageUrl': item.imageUrl,
      'mediaUrl': item.mediaUrl,
      'positionSeconds': seconds,
      'durationSeconds': total,
      'progress': total > 0 ? seconds / total : 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> recordWatchStarted(String uid, AurenEntertainmentItem item) async {
    if (uid.isEmpty || item.id.isEmpty) return;
    await db.collection('users').doc(uid).collection('watchHistory').doc(item.id).set({
      'itemId': item.id,
      'title': item.title,
      'type': item.type,
      'imageUrl': item.imageUrl,
      'mediaUrl': item.mediaUrl,
      'lastWatchedAt': FieldValue.serverTimestamp(),
      'views': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<void> recordWatchProgress(
    String uid,
    AurenEntertainmentItem item, {
    required int seconds,
    required int durationSeconds,
    required bool completed,
  }) async {
    if (uid.isEmpty || item.id.isEmpty) return;
    await db.collection('users').doc(uid).collection('watchHistory').doc(item.id).set({
      'itemId': item.id,
      'title': item.title,
      'type': item.type,
      'imageUrl': item.imageUrl,
      'mediaUrl': item.mediaUrl,
      'lastPositionSeconds': seconds,
      'durationSeconds': durationSeconds,
      'progress': durationSeconds > 0 ? (seconds / durationSeconds).clamp(0.0, 1.0) : 0.0,
      'completed': completed,
      'lastWatchedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> watchHistory(String uid) {
    return db.collection('users').doc(uid).collection('watchHistory')
        .orderBy('lastWatchedAt', descending: true).limit(30).snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<Map<String, dynamic>?> getWatchProgress(String uid, String itemId) async {
    if (uid.isEmpty || itemId.isEmpty) return null;
    final doc = await db.collection('users').doc(uid).collection('continueWatching').doc(itemId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<Map<String, Map<String, dynamic>>> getMusicSignals(String uid) async {
    final snap = await db.collection('users').doc(uid).collection('entertainmentSignals').get();
    return {
      for (final d in snap.docs)
        d.id: d.data(),
    };
  }


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
