import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/post.dart';
import '../social/post_repository.dart';

class AurenCoreFiveSnapshot {
  final int activeGoals, businesses, products, creatorDrafts, posts;
  final List<String> goalTitles, businessNames, productNames, draftTitles;
  final String? firstBusinessId, firstProductId;
  final int averageGoalProgress;
  final int totalSignals;
  final bool hasGoal, hasBusiness, hasProduct, hasCreatorDraft, hasPulse;

  const AurenCoreFiveSnapshot({
    required this.activeGoals,
    required this.businesses,
    required this.products,
    required this.creatorDrafts,
    required this.posts,
    required this.goalTitles,
    required this.businessNames,
    required this.productNames,
    required this.draftTitles,
    required this.firstBusinessId,
    required this.firstProductId,
    required this.averageGoalProgress,
    required this.totalSignals,
    required this.hasGoal,
    required this.hasBusiness,
    required this.hasProduct,
    required this.hasCreatorDraft,
    required this.hasPulse,
  });

  String get recommendedModule =>
      activeGoals == 0 ? 'Personal AI' :
      businesses == 0 ? 'Business' :
      products == 0 ? 'Marketplace' :
      creatorDrafts == 0 ? 'Creator Studio' :
      posts == 0 ? 'Social / Pulse' : 'Business';

  String get nextMove {
    if (activeGoals == 0) return 'ابدأ هدفًا واحدًا في Personal AI ثم حوّله إلى خطوة عملية.';
    if (businesses == 0) return 'أنشئ أول Business أو خدمة، ثم اربطها بباقي AUREN.';
    if (products == 0) return 'أضف أول منتج أو خدمة إلى Marketplace من Business.';
    if (creatorDrafts == 0) return 'حوّل هدفك أو خبرتك إلى أول مسودة محتوى في Creator Studio.';
    if (posts == 0) return 'انشر أول فكرة أو فرصة في Pulse وابنِ اتصالًا حولها.';
    if (averageGoalProgress < 50) return 'ارجع للهدف النشط ونفّذ خطوة صغيرة ترفع تقدمه اليوم.';
    return 'اربط ما أنشأته بفرصة جديدة: محتوى، عميل، منتج أو شراكة.';
  }

  int get readinessPercent => [hasGoal, hasPulse, hasBusiness, hasProduct, hasCreatorDraft].where((v) => v).length * 20;

  String get readinessLabel {
    if (readinessPercent == 0) return 'البداية';
    if (readinessPercent < 60) return 'قيد البناء';
    if (readinessPercent < 100) return 'يتوسع';
    return 'Core 5 متصل';
  }

  String get actionTitle => 'الخطوة التالية: $recommendedModule';

  String toPrompt() => 'أنت AUREN AI. حلّل وضعي عبر الوحدات الخمس الأساسية واصنع لي خطوة عملية واحدة الآن.\n'
      'Personal AI: $activeGoals أهداف نشطة (متوسط التقدم $averageGoalProgress%)${goalTitles.isEmpty ? '' : ' — ${goalTitles.join('، ')}'}.\n'
      'Social / Pulse: $posts منشورًا.\n'
      'Business: $businesses أنشطة${businessNames.isEmpty ? '' : ' — ${businessNames.join('، ')}'}.\n'
      'Marketplace: $products منتجات/خدمات${productNames.isEmpty ? '' : ' — ${productNames.join('، ')}'}.\n'
      'Creator Studio: $creatorDrafts مسودات${draftTitles.isEmpty ? '' : ' — ${draftTitles.join('، ')}'}.\n'
      'إجمالي الإشارات القابلة للتحويل: $totalSignals.\n'
      'اربط الوحدات ببعضها، وحوّل هدفي إلى محتوى أو فرصة أو منتج أو خطوة Business. أعطني الخطوة التالية القابلة للتنفيذ.';

}

class AurenCoreFiveRepository {
  final FirebaseFirestore db;

  AurenCoreFiveRepository({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  Future<QuerySnapshot<Map<String, dynamic>>?> _safe(
    Future<QuerySnapshot<Map<String, dynamic>>> request,
  ) async {
    try {
      return await request;
    } catch (_) {
      return null;
    }
  }

  Future<String?> createCreatorDraftFromTopGoal(String uid) async {
    final goals = await db.collection('users').doc(uid).collection('goals').limit(50).get();
    final active = goals.docs.where((d) => (d.data()['status']?.toString() ?? 'active') == 'active').toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => (b.data()['updatedAt']?.toString() ?? '').compareTo(a.data()['updatedAt']?.toString() ?? ''));
    final data = active.first.data();
    final title = data['title']?.toString().trim() ?? '';
    if (title.isEmpty) return null;
    final description = data['description']?.toString().trim() ?? '';
    final draftId = 'core5_${uid}_${active.first.id}';
    final draft = db.collection('creator_drafts').doc(draftId);
    if ((await draft.get()).exists) return draft.id;
    await draft.set({
      'ownerId': uid,
      'title': title,
      'body': description.isEmpty
          ? 'فكرة محتوى مرتبطة بهذا الهدف: $title\n\nشارك لماذا هذا الهدف مهم، ما الذي تتعلمه منه، وما الخطوة التالية التي تعمل عليها.'
          : 'هدفي: $title\n\n$description\n\nالخطوة التالية: شارك تقدمك، ما تعلمته، وما الذي ستفعله بعد ذلك.',
      'status': 'draft',
      'source': 'core_five_goal_bridge',
      'sourceGoalId': active.first.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return draft.id;
  }

  Future<({String? draftId, String? postId})> runCoreFiveBatch(String uid) async {
    final goals = await db.collection('users').doc(uid).collection('goals').limit(50).get();
    final active = goals.docs.where((d) => (d.data()['status']?.toString() ?? 'active') == 'active').toList();
    if (active.isEmpty) return (draftId: null, postId: null);
    active.sort((a, b) => (b.data()['updatedAt']?.toString() ?? '').compareTo(a.data()['updatedAt']?.toString() ?? ''));
    final data = active.first.data();
    final title = data['title']?.toString().trim() ?? '';
    if (title.isEmpty) return (draftId: null, postId: null);
    final description = data['description']?.toString().trim() ?? '';
    final draftId = 'core5_${uid}_${active.first.id}';
    final postId = draftId;
    final draftRef = db.collection('creator_drafts').doc(draftId);
    final postRef = db.collection('posts').doc(postId);
    final existingDraft = await draftRef.get();
    final existingPost = await postRef.get();
    final batch = db.batch();

    if (!existingDraft.exists) {
      batch.set(draftRef, {
        'ownerId': uid,
        'title': title,
        'body': description.isEmpty
            ? 'فكرة محتوى مرتبطة بهذا الهدف: $title\n\nشارك لماذا هذا الهدف مهم، ما الذي تتعلمه منه، وما الخطوة التالية التي تعمل عليها.'
            : 'هدفي: $title\n\n$description\n\nالخطوة التالية: شارك تقدمك، ما تعلمته، وما الذي ستفعله بعد ذلك.',
        'status': 'draft',
        'source': 'core_five_goal_bridge',
        'sourceGoalId': active.first.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    if (!existingPost.exists) {
      final text = description.isEmpty
          ? 'هدفي الحالي: $title\n\nأشارك تقدمي والخطوة التالية التي أعمل عليها مع مجتمع AUREN.'
          : 'هدفي الحالي: $title\n\n$description\n\nالخطوة التالية: أشارك تقدمي وما سأفعله بعد ذلك.';
      batch.set(postRef, {
        'authorId': uid,
        'text': text,
        'mediaUrl': '',
        'mediaType': 'none',
        'contentType': 'project',
        'contextLabel': 'Building now',
        'actionLabel': 'Join',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'likes': 0,
        'comments': 0,
        'searchText': text.trim().toLowerCase(),
      });
    }
    if (!existingDraft.exists || !existingPost.exists) await batch.commit();
    return (draftId: draftId, postId: postId);
  }

  Future<String?> createPulseFromTopGoal(String uid) async {
    final goals = await db.collection('users').doc(uid).collection('goals').limit(50).get();
    final active = goals.docs.where((d) => (d.data()['status']?.toString() ?? 'active') == 'active').toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => (b.data()['updatedAt']?.toString() ?? '').compareTo(a.data()['updatedAt']?.toString() ?? ''));
    final data = active.first.data();
    final title = data['title']?.toString().trim() ?? '';
    if (title.isEmpty) return null;
    final description = data['description']?.toString().trim() ?? '';
    final id = 'core5_${uid}_${active.first.id}';
    final existing = await db.collection('posts').doc(id).get();
    if (existing.exists) return id;
    await PostRepository().create(
      AurenPost(
        id: id,
        authorId: uid,
        text: description.isEmpty
            ? 'هدفي الحالي: $title\n\nأشارك تقدمي والخطوة التالية التي أعمل عليها مع مجتمع AUREN.'
            : 'هدفي الحالي: $title\n\n$description\n\nالخطوة التالية: أشارك تقدمي وما سأفعله بعد ذلك.',
        mediaUrl: '',
        mediaType: 'none',
        contentType: 'project',
        contextLabel: 'Building now',
        actionLabel: 'Join',
        createdAt: DateTime.now(),
      ),
    );
    return id;
  }

  Future<AurenCoreFiveSnapshot> load(String uid) async {
    final r = await Future.wait<QuerySnapshot<Map<String, dynamic>>?>([
      _safe(db.collection('users').doc(uid).collection('goals').limit(50).get()),
      _safe(db.collection('businesses').where('ownerId', isEqualTo: uid).limit(50).get()),
      _safe(db.collection('products').where('ownerId', isEqualTo: uid).limit(100).get()),
      _safe(db.collection('creator_drafts').where('ownerId', isEqualTo: uid).limit(50).get()),
      _safe(db.collection('posts').where('authorId', isEqualTo: uid).limit(100).get()),
    ]);

    final goals = (r[0]?.docs ?? const [])
        .where((d) => (d.data()['status']?.toString() ?? 'active') == 'active')
        .toList();

    List<String> names(QuerySnapshot<Map<String, dynamic>>? snapshot, String key) =>
        (snapshot?.docs ?? const [])
            .map((d) => d.data()[key]?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty)
            .take(5)
            .toList();

    return AurenCoreFiveSnapshot(
      hasGoal: goals.isNotEmpty,
      hasBusiness: (r[1]?.docs.isNotEmpty ?? false),
      hasProduct: (r[2]?.docs.isNotEmpty ?? false),
      hasCreatorDraft: (r[3]?.docs.isNotEmpty ?? false),
      hasPulse: (r[4]?.docs.isNotEmpty ?? false),
      activeGoals: goals.length,
      businesses: r[1]?.docs.length ?? 0,
      products: r[2]?.docs.length ?? 0,
      creatorDrafts: r[3]?.docs.length ?? 0,
      posts: r[4]?.docs.length ?? 0,
      goalTitles: goals
          .map((d) => d.data()['title']?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .take(5)
          .toList(),
      businessNames: names(r[1], 'name'),
      productNames: names(r[2], 'name'),
      draftTitles: names(r[3], 'title'),
      firstBusinessId: r[1]?.docs.isNotEmpty == true ? r[1]!.docs.first.id : null,
      firstProductId: r[2]?.docs.isNotEmpty == true ? r[2]!.docs.first.id : null,
      averageGoalProgress: goals.isEmpty ? 0 : goals.fold<int>(0, (sum, d) => sum + ((d.data()['progress'] as num?)?.toInt() ?? 0)) ~/ goals.length,
      totalSignals: goals.length + (r[1]?.docs.length ?? 0) + (r[2]?.docs.length ?? 0) + (r[3]?.docs.length ?? 0) + (r[4]?.docs.length ?? 0),
    );
  }
}
