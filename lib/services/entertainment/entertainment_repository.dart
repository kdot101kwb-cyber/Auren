import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/entertainment.dart';

class EntertainmentRepository {
  final FirebaseFirestore db;
  EntertainmentRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AurenEntertainmentItem>> searchEntertainment(String query) {
    final terms=query.trim().toLowerCase().split(' ').where((v)=>v.isNotEmpty).toList();
    if(terms.isEmpty) return watchItems();
    return watchItems().map((items)=>items.where((item){
      final hay='${item.title} ${item.description} ${item.type} ${item.country} ${item.language} ${item.year} ${item.genres.join(' ')} ${item.artistName} ${item.albumName} ${item.source}'.toLowerCase();
      return terms.every(hay.contains);
    }).toList()
      ..sort((a, b) {
        final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
      });
  }

  Stream<List<AurenEntertainmentItem>> watchAiRecommendations(String uid) {
    return db.collection('entertainment_items').where('visibility',isEqualTo:'public').limit(100).snapshots().asyncMap((snap) async {
      final items=snap.docs.map((d)=>AurenEntertainmentItem.fromMap(d.id,d.data())).where((i)=>i.mediaUrl.isNotEmpty).toList();
      final signals=await db.collection('users').doc(uid).collection('entertainmentSignals').get();
      final scores=<String,double>{};
      for(final d in signals.docs){
        final data=d.data();
        final watchSeconds=(data['watchSeconds'] as num?)?.toDouble()??0;
        final views=(data['views'] as num?)?.toDouble()??0;
        final likes=(data['likes'] as num?)?.toDouble()??0;
        final saves=(data['saves'] as num?)?.toDouble()??0;
        final completions=(data['completions'] as num?)?.toDouble()??0;
        final skips=(data['skips'] as num?)?.toDouble()??0;
        var score=watchSeconds*.02+views*.35+likes*5+saves*4+completions*3-skips*2;
        if(views==0 && likes==0 && saves==0) score+=6;
        scores[d.id]=score;
      }
      items.sort((a,b){
        final scoreCompare=(scores[b.id]??6).compareTo(scores[a.id]??6);
        if(scoreCompare!=0) return scoreCompare;
        final titleCompare=a.title.toLowerCase().compareTo(b.title.toLowerCase());
        return titleCompare!=0 ? titleCompare : a.id.compareTo(b.id);
      });
      return items;
    });
  }

  Future<String> createWatchTogetherRoom(String uid, {required String itemId, required String title}) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) throw StateError('سجّل الدخول أولاً.');
    if (uid != currentUid) throw StateError('لا يمكن إنشاء غرفة باسم مستخدم آخر.');
    final safeItemId = itemId.trim();
    if (safeItemId.isEmpty) throw StateError('المحتوى المطلوب للمشاهدة غير صالح.');
    final ref = db.collection('watchTogetherRooms').doc();
    final safeTitle = title.trim().isEmpty ? 'Watch Together' : title.trim();
    await db.runTransaction((tx) async {
      tx.set(ref, {
        'hostUid': currentUid,
        'memberUids': [currentUid],
        'itemId': safeItemId,
        'title': safeTitle.length > 200 ? safeTitle.substring(0, 200) : safeTitle,
        'status': 'waiting',
        'positionSeconds': 0,
        'isPlaying': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return ref.id;
  }

  Future<void> joinWatchTogetherRoom(String roomId, String uid) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) throw StateError('سجّل الدخول أولاً.');
    if (uid != currentUid) throw StateError('لا يمكن الانضمام باسم مستخدم آخر.');
    final ref = db.collection('watchTogetherRooms').doc(roomId);
    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('الغرفة غير متاحة.');
      final data = snap.data() ?? <String, dynamic>{};
      final members = List<String>.from(data['memberUids'] ?? const <String>[]);
      if (members.contains(uid)) return;
      if (members.length >= 8) throw StateError('الغرفة ممتلئة.');
      members.add(uid);
      tx.update(ref, {
        'memberUids': members,
        'status': 'ready',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<Map<String, dynamic>?> watchTogetherRoom(String roomId) =>
      db.collection('watchTogetherRooms').doc(roomId).snapshots().map(
        (d) => d.exists ? {'id': d.id, ...?d.data()} : null,
      );

  Future<void> updateWatchTogetherPlayback(
    String roomId, {
    required int positionSeconds,
    required bool isPlaying,
  }) async {
    final ref = db.collection('watchTogetherRooms').doc(roomId);
    final snap = await ref.get();
    if (!snap.exists) throw StateError('الغرفة غير متاحة.');
    final data = snap.data() ?? <String, dynamic>{};
    if (data['hostUid'] != FirebaseAuth.instance.currentUser?.uid) {
      throw StateError('المضيف فقط يستطيع التحكم في التشغيل.');
    }
    await ref.update({
      'positionSeconds': positionSeconds.clamp(0, 86400),
      'isPlaying': isPlaying,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

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
    if (maxItems <= 0) return const [];

    final items = <AurenEntertainmentItem>[];
    for (final doc in docs) {
      final data = doc.data();
      final item = AurenEntertainmentItem.fromMap(doc.id, data);
      if (!item.isVideo || item.mediaUrl.isEmpty) continue;
      if (mood != null &&
          mood.isNotEmpty &&
          mood != 'تسلية' &&
          !_itemMatchesMood(data, mood)) {
        continue;
      }
      items.add(item);
      if (items.length >= maxItems) break;
    }
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

  Future<Set<String>> getLikedPodcastEpisodeIds(String uid) async {
    final snap = await db.collection('users').doc(uid).collection('podcastLikes').get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Future<Set<String>> getSavedPodcastEpisodeIds(String uid) async {
    final snap = await db.collection('users').doc(uid).collection('podcastEpisodeSaves').get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Future<List<Map<String, dynamic>>> getSavedPodcastEpisodes(String uid) async {
    final snap = await db.collection('users').doc(uid).collection('podcastEpisodeSaves')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> togglePodcastEpisodeSave(
    String uid,
    String episodeId,
    bool saved, {
    String? title,
    String? podcastId,
    String? podcastName,
    String? feedUrl,
    String? description,
    String? artworkUrl,
    String? audioUrl,
    String? publishedAt,
    String? language,
    String? country,
    bool isVideo = false,
  }) async {
    final ref = db.collection('users').doc(uid).collection('podcastEpisodeSaves').doc(episodeId);
    if (saved) {
      await ref.set({
        'episodeId': episodeId,
        'title': title ?? '',
        'podcastId': podcastId ?? '',
        'podcastName': podcastName ?? '',
        'feedUrl': feedUrl ?? '',
        'description': description ?? '',
        'artworkUrl': artworkUrl ?? '',
        'audioUrl': audioUrl ?? '',
        'publishedAt': publishedAt ?? '',
        'language': language ?? '',
        'country': country ?? '',
        'isVideo': isVideo,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }

  Future<void> setPodcastEpisodeOffline(String uid, String episodeId, bool offline) async {
    final ref = db.collection('users').doc(uid).collection('podcastEpisodeSaves').doc(episodeId);
    await ref.set({'offline': offline}, SetOptions(merge: true));
  }

  Future<void> togglePodcastLike(String uid, String episodeId, bool liked, {String? title, String? podcastId}) async {
    final ref = db.collection('users').doc(uid).collection('podcastLikes').doc(episodeId);
    if (liked) {
      await ref.set({'episodeId': episodeId, 'title': title ?? '', 'podcastId': podcastId ?? '', 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }

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

  Stream<List<Map<String, dynamic>>> watchSeriesWatchProgress(String uid) {
    return db.collection('users').doc(uid).collection('seriesWatchProgress')
        .orderBy('updatedAt', descending: true).limit(50).snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<Map<String, dynamic>?> getSeriesWatchProgress(
    String uid,
    String jobId,
    int episodeNumber,
  ) async {
    final id = 'job_${jobId}_ep_${episodeNumber}';
    final d = await db.collection('users').doc(uid).collection('seriesWatchProgress').doc(id).get();
    if (!d.exists) return null;
    return {'id': d.id, ...?d.data()};
  }

  Future<void> saveSeriesWatchProgress(
    String uid,
    String jobId,
    int episodeNumber, {
    required int positionSeconds,
    required int durationSeconds,
    String? title,
    String? videoUrl,
    bool completed = false,
  }) async {
    if (uid.isEmpty || jobId.isEmpty || episodeNumber < 1) return;
    final id = 'job_${jobId}_ep_${episodeNumber}';
    final position = positionSeconds.clamp(0, durationSeconds > 0 ? durationSeconds : positionSeconds);
    await db.collection('users').doc(uid).collection('seriesWatchProgress').doc(id).set({
      'jobId': jobId,
      'episodeNumber': episodeNumber,
      'title': title ?? '',
      'videoUrl': videoUrl ?? '',
      'positionSeconds': position,
      'durationSeconds': durationSeconds,
      'progress': durationSeconds > 0 ? (position / durationSeconds).clamp(0.0, 1.0) : 0.0,
      'completed': completed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearSeriesWatchProgress(String uid, String jobId, int episodeNumber) {
    return db.collection('users').doc(uid).collection('seriesWatchProgress')
        .doc('job_${jobId}_ep_${episodeNumber}').delete();
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
      'provider': 'pollinations',
      'progress': 0,
      'plan': _creationPlan(mode),
      'assets': _creationAssets(mode),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  List<String> _creationPlan(String mode) {
    switch (mode) {
      case 'أغنية': return ['Concept وكلمات','لحن وتوزيع','صوت/أداء','Mix & Master','مراجعة الحقوق','Ready'];
      case 'فيلم': return ['Concept وScript','Story & Characters','Storyboard','الأصول البصرية','الصوت والموسيقى','المونتاج','مراجعة الحقوق','Ready'];
      case 'فيديو': return ['Concept وScript','Storyboard','الأصول البصرية','الصوت والموسيقى','المونتاج','مراجعة الحقوق','Ready'];
      case 'بودكاست': return ['الفكرة والهيكل','Script/Notes','تسجيل الصوت','تنظيف ومكساج','غلاف ووصف','مراجعة الحقوق','Ready'];
      case 'عالم': return ['تصميم العالم','الشخصيات والأماكن','المهام والتفاعل','الأصول الصوتية والبصرية','اختبار التجربة','Ready'];
      case 'مسلسل': return ['Series Bible','Characters','Season Arc','Episode Bibles','Scenes & Shots','Assets','Voice/Music','Assembly','QC','Ready'];
      default: return ['Concept','السيناريو','الشخصيات والمشاهد','الصوت والأصول','المراجعة','Ready'];
    }
  }

  List<String> _creationAssets(String mode) {
    switch (mode) {
      case 'أغنية': return ['lyrics','music','vocals','artwork'];
      case 'فيلم': return ['film_bible','script','characters','storyboard','visual_assets','video','audio','music','thumbnail','trailer','qc'];
      case 'فيديو': return ['script','storyboard','video','audio','thumbnail'];
      case 'بودكاست': return ['script','voice','cover','description'];
      case 'عالم': return ['world','characters','locations','missions','audio'];
      case 'مسلسل': return ['series_bible','characters','season_arc','episode_bibles','scenes','shots','visual_assets','voices','music_sfx','renders','qc'];
      default: return ['story','characters','scenes','artwork'];
    }
  }
  /// Generates and persists the server-owned series blueprint for a creation job.
  Future<Map<String, dynamic>> generateMovieBlueprint(String jobId) async {
    final id = jobId.trim();
    if (id.isEmpty) throw ArgumentError('jobId is required');
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('generateAurenMovieBlueprint');
    final response = await callable.call({'jobId': id});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> createMusicProductionJob(
    String uid, {
    required String title,
    required String prompt,
    required String genre,
    required String mood,
    required String language,
    int durationSeconds = 30,
  }) async {
    if (uid.trim().isEmpty) throw ArgumentError('uid is required');
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('createAurenMusicProductionJob');
    final response = await callable.call({
      'title': title.trim().isEmpty ? 'AUREN Original Track' : title.trim(),
      'prompt': prompt.trim(),
      'genre': genre,
      'mood': mood,
      'language': language,
      'durationSeconds': durationSeconds.clamp(10, 300),
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Stream<Map<String, dynamic>?> watchMusicProductionJob(String uid, String jobId) {
    return db.collection('users').doc(uid).collection('musicProductionJobs').doc(jobId)
        .snapshots().map((d) => d.exists ? {'id': d.id, ...d.data()!} : null);
  }

  Future<Map<String, dynamic>> generateMusicBlueprint(String jobId) async {
    final id = jobId.trim();
    if (id.isEmpty) throw ArgumentError('jobId is required');
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('generateAurenMusicBlueprint');
    final response = await callable.call({'jobId': id});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> generateSeriesBlueprint(String jobId) async {
    final id = jobId.trim();
    if (id.isEmpty) throw ArgumentError('jobId is required');
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('generateAurenSeriesBlueprint');
    final response = await callable.call({'jobId': id});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>?> getEntertainmentCreationJob(
    String uid,
    String jobId,
  ) async {
    if (uid.isEmpty || jobId.isEmpty) return null;
    final doc = await db.collection('users').doc(uid)
        .collection('entertainmentCreationJobs').doc(jobId).get();
    return doc.exists ? {'id': doc.id, ...doc.data()!} : null;
  }

  Stream<Map<String, dynamic>?> watchEntertainmentCreationJob(
    String uid,
    String jobId,
  ) {
    return db.collection('users').doc(uid).collection('entertainmentCreationJobs').doc(jobId)
        .snapshots()
        .map((d) => d.exists ? {'id': d.id, ...d.data()!} : null);
  }

  Future<void> retryEntertainmentJob(String uid, String jobId) async {
    if (uid.isEmpty || jobId.isEmpty) return;
    await updateEntertainmentJobStatus(uid, jobId, status: 'planning', progress: 0);
  }

  Future<void> cancelEntertainmentJob(String uid, String jobId) async {
    if (uid.isEmpty || jobId.isEmpty) return;
    await updateEntertainmentJobStatus(uid, jobId, status: 'cancelled', progress: 0);
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


  Future<Map<String, dynamic>?> getFinalEpisodePackage(String jobId) async {
    final id = jobId.trim();
    if (id.isEmpty) return null;
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('getAurenFinalEpisodePackage');
    final response = await callable.call({'jobId': id});
    if (response.data is! Map) return null;
    return Map<String, dynamic>.from(response.data as Map);
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
