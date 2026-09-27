import 'package:cloud_firestore/cloud_firestore.dart';

class SeriesProductionService {
  final FirebaseFirestore db;
  SeriesProductionService({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _projects(String uid) =>
      db.collection('users').doc(uid).collection('seriesProjects');

  /// Global daily capacity for the Series Studio queue.
  static const int dailySeriesLimit = 5;

  Future<int?> reserveDailySeriesSlot(String uid) async {
    if (uid.isEmpty) return null;
    final now = DateTime.now().toUtc();
    final dayKey = now.toIso8601String().substring(0, 10);
    final ref = db.collection('seriesProductionDays').doc(dayKey);
    return db.runTransaction<int?>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};
      final reserved = (data['reserved'] as num?)?.toInt() ?? 0;
      if (reserved >= dailySeriesLimit) return null;
      final slot = reserved + 1;
      tx.set(ref, {
        'dayKey': dayKey,
        'limit': dailySeriesLimit,
        'reserved': slot,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return slot;
    });
  }

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


  /// Creates the five original concepts selected for Series Batch #001.
  /// This creates production-ready planning records; it does not claim that
  /// video/audio media has been rendered.
  Future<List<String>> createSeriesBatch001(String uid) async {
    if (uid.isEmpty) return const [];
    final now = DateTime.now().toUtc();
    final dayKey = now.toIso8601String().substring(0, 10);
    final dayRef = db.collection('seriesProductionDays').doc(dayKey);

    const catalog = <Map<String, dynamic>>[
      {
        'title': 'التقاء',
        'idea': 'شاب سوداني يعثر على جهاز غامض مرتبط بنهرين، ويبدأ باستقبال رسائل من احتمالات مستقبلية؛ كل محاولة لتغيير المستقبل تخلق نتيجة جديدة.',
        'genre': 'دراما + غموض + خيال علمي',
        'tone': 'سينمائي',
        'episodeCount': 8,
        'episodeLength': '20 دقيقة',
        'logline': 'رسائل من مستقبل محتمل تدفع شاباً إلى اكتشاف سر يربط حياته بمسارين متوازيين.',
        'characters': ['آدم — شاب فضولي يبحث عن معنى الجهاز', 'سارة — باحثة تساعده على فك الإشارات', 'نادر — شخص يعرف جزءاً من تاريخ الجهاز', 'الصوت — مرسل مجهول من احتمال مستقبلي'],
        'episodes': ['الجهاز','الرسالة الأولى','المسار الثاني','الاختيار','الانقسام','العودة','الحقيقة','الالتقاء'],
      },
      {
        'title': 'المدينة التي لا تنام',
        'idea': 'شباب من دول مختلفة يصلون إلى مدينة عالمية تبدو طبيعية، ثم يكتشفون نظاماً سرياً يراقب قرارات السكان ويوجه حياتهم.',
        'genre': 'غموض + أكشن + دراما',
        'tone': 'مظلم',
        'episodeCount': 10,
        'episodeLength': '20 دقيقة',
        'logline': 'مدينة مثالية ظاهرياً تخفي نظاماً يغيّر اختيارات سكانها.',
        'characters': ['ليان — صحفية شابة', 'مالك — مطور أنظمة', 'نورا — صانعة محتوى', 'إياد — سائق يعرف المدينة جيداً'],
        'episodes': ['الوصول','العلامة','الكاميرا','الخريطة','الغرفة','الاختفاء','المقاومة','الحقيقة الناقصة','المدينة الثانية','القرار'],
      },
      {
        'title': 'آخر اتصال',
        'idea': 'بعد انقطاع عالمي للاتصالات، يتلقى شاب رسالة من شخص يدّعي أنه يتحدث من بعد ثلاثين عاماً، وتحتوي الرسالة على تفاصيل دقيقة من حياته لم تحدث بعد.',
        'genre': 'خيال علمي + دراما + إثارة',
        'tone': 'غامض',
        'episodeCount': 8,
        'episodeLength': '20 دقيقة',
        'logline': 'اتصال مستحيل من المستقبل يضع حاضراً كاملاً أمام سؤال: هل يمكن تغيير ما نعرفه مسبقاً؟',
        'characters': ['يوسف — مهندس اتصالات', 'ميرا — صحفية تحقق في الانقطاع', 'المرسل — هوية مجهولة', 'سامر — صديق يوسف وشريكه في البحث'],
        'episodes': ['الصمت','الرسالة','بعد ثلاثين عاماً','الدليل','التحذير','المطاردة','الاختيار','آخر اتصال'],
      },
      {
        'title': 'العالم الآخر',
        'idea': 'أربعة أصدقاء يدخلون عالماً افتراضياً تتحول فيه مهاراتهم الواقعية إلى قدرات، ثم يكتشفون أن أحداث العالم الافتراضي تؤثر في العالم الحقيقي.',
        'genre': 'مغامرة + فانتازيا + ألعاب + كوميديا',
        'tone': 'خفيف',
        'episodeCount': 12,
        'episodeLength': '20 دقيقة',
        'logline': 'لعبة تبدو ممتعة تتحول إلى عالم حي يحتاج أبطاله إلى التعاون للعودة إلى الواقع.',
        'characters': ['رامي — صانع ألعاب', 'جود — رياضية', 'زين — مخترع', 'تالا — صانعة محتوى'],
        'episodes': ['الدخول','اختيار المهارة','المدينة الأولى','المهمة','المتاهة','الفريق','المستوى السري','العالم المعكوس','الخلل','الخروج','العودة','الحقيقة'],
      },
      {
        'title': 'المفقودون',
        'idea': 'أشخاص من دول مختلفة يستيقظون في أماكن متباعدة، وكل واحد يحمل جزءاً من خريطة واحدة؛ جمع الأجزاء يكشف سراً قديماً.',
        'genre': 'غموض + مغامرة + دراما',
        'tone': 'سينمائي',
        'episodeCount': 8,
        'episodeLength': '30 دقيقة',
        'logline': 'ثمانية غرباء يحمل كل منهم قطعة من لغز واحد، وعليهم التعاون قبل أن تختفي الخريطة.',
        'characters': ['مريم — باحثة في التاريخ', 'عمر — مصور رحلات', 'آنا — مهندسة خرائط', 'داود — تاجر تحف', 'مجموعة المفقودين — شخصيات من دول متعددة'],
        'episodes': ['الاستيقاظ','القطعة الأولى','العلامة القديمة','اللقاء','الخريطة','المطاردون','المكان الأخير','السر'],
      },
    ];

    final projectRefs = <DocumentReference<Map<String, dynamic>>>[];
    final projectPlans = <Map<String, dynamic>>[];

    await db.runTransaction((tx) async {
      final daySnap = await tx.get(dayRef);
      final day = daySnap.data() ?? <String, dynamic>{};
      final reserved = (day['reserved'] as num?)?.toInt() ?? 0;
      if (reserved + catalog.length > dailySeriesLimit) {
        throw StateError('daily_series_capacity_reached');
      }

      tx.set(dayRef, {
        'dayKey': dayKey,
        'limit': dailySeriesLimit,
        'reserved': reserved + catalog.length,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      for (var i = 0; i < catalog.length; i++) {
        final item = catalog[i];
        final ref = _projects(uid).doc();
        projectRefs.add(ref);
        projectPlans.add(item);
        tx.set(ref, {
          'batchId': 'series_batch_001',
          'batchSlot': i + 1,
          'title': item['title'],
          'idea': item['idea'],
          'genre': item['genre'],
          'tone': item['tone'],
          'episodeCount': item['episodeCount'],
          'episodeLength': item['episodeLength'],
          'logline': item['logline'],
          'characters': item['characters'],
          'status': 'planned',
          'stage': 'episode_bibles',
          'progress': 20,
          'rightsStatus': 'pending_review',
          'stages': const [
            'series_bible','characters','season_arc','episode_bibles',
            'scene_breakdown','assets','voice_music','assembly','qc','ready'
          ],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    final batch = db.batch();
    for (var i = 0; i < projectRefs.length; i++) {
      final ref = projectRefs[i];
      final item = projectPlans[i];
      final titles = (item['episodes'] as List).cast<String>();
      for (var e = 0; e < titles.length; e++) {
        final ep = ref.collection('episodes').doc('episode_' + (e + 1).toString().padLeft(2, '0'));
        batch.set(ep, {
          'episodeNumber': e + 1,
          'title': titles[e],
          'summary': 'تطوير حلقة أصلية ضمن ' + item['title'].toString() + '، مع الحفاظ على استمرارية الشخصيات والعالم.',
          'status': 'planned',
          'stage': 'scene_breakdown',
          'progress': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
    return projectRefs.map((e) => e.id).toList();
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
