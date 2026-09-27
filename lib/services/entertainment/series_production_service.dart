import 'package:cloud_firestore/cloud_firestore.dart';

class SeriesProductionService {
  final FirebaseFirestore db;
  SeriesProductionService({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _projects(String uid) =>
      db.collection('users').doc(uid).collection('seriesProjects');

  Future<String> createSeriesProject(String uid, {
    required String title, required String idea, required String genre,
    required String tone, required int episodeCount, required String episodeLength,
  }) async {
    final ref = _projects(uid).doc();
    const stages = ['series_bible','characters','season_arc','episode_bibles',
      'scene_breakdown','assets','voice_music','assembly','qc','ready'];
    await ref.set({
      'title': title.trim().isEmpty ? 'Untitled Series' : title.trim(),
      'idea': idea.trim(), 'genre': genre, 'tone': tone,
      'episodeCount': episodeCount, 'episodeLength': episodeLength,
      'status': 'planning', 'stage': stages.first, 'progress': 0,
      'rightsStatus': 'pending_review', 'stages': stages,
      'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> seedSeasonPlan(String uid, String projectId, {
    required Map<String, dynamic> bible,
    required List<Map<String, dynamic>> characters,
    required Map<String, dynamic> seasonArc,
    required List<Map<String, dynamic>> episodes,
  }) async {
    final ref = _projects(uid).doc(projectId);
    final batch = db.batch();
    batch.set(ref, {
      'seriesBible': bible, 'characters': characters, 'seasonArc': seasonArc,
      'episodeCount': episodes.length, 'status': 'planned',
      'stage': 'episode_bibles', 'progress': 20,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    for (var i = 0; i < episodes.length; i++) {
      final id = 'episode_' + (i + 1).toString().padLeft(2, '0');
      final ep = ref.collection('episodes').doc(id);
      batch.set(ep, {...episodes[i], 'episodeNumber': i + 1, 'status': 'planned',
        'stage': 'scene_breakdown', 'progress': 0,
        'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Stream<Map<String, dynamic>?> watchProject(String uid, String projectId) =>
      _projects(uid).doc(projectId).snapshots().map(
        (d) => d.exists ? {'id': d.id, ...d.data()!} : null);

  Stream<List<Map<String, dynamic>>> watchEpisodes(String uid, String projectId) =>
      _projects(uid).doc(projectId).collection('episodes').orderBy('episodeNumber')
        .snapshots().map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<String> createEpisodeJob(String uid, String projectId, int episodeNumber) async {
    final id = 'episode_' + episodeNumber.toString().padLeft(2, '0');
    final ep = _projects(uid).doc(projectId).collection('episodes').doc(id);
    await ep.set({'status': 'queued', 'stage': 'scene_breakdown', 'progress': 0,
      'queuedAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true));
    return ep.id;
  }

  Future<String> addSceneJob(String uid, String projectId, int episodeNumber, {
    required int sceneNumber, required Map<String, dynamic> scene,
  }) async {
    final id = 'episode_' + episodeNumber.toString().padLeft(2, '0');
    final ep = _projects(uid).doc(projectId).collection('episodes').doc(id);
    final ref = ep.collection('scenes').doc('scene_' + sceneNumber.toString().padLeft(3, '0'));
    await ref.set({...scene, 'sceneNumber': sceneNumber, 'status': 'queued',
      'stage': 'assets', 'progress': 0, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true));
    return ref.id;
  }

  Future<void> updateStage(String uid, String projectId, {
    required String stage, required int progress, required String status,
  }) => _projects(uid).doc(projectId).update({
    'stage': stage, 'progress': progress.clamp(0, 100), 'status': status,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
