import 'package:cloud_firestore/cloud_firestore.dart';

class AurenCoreFiveSnapshot {
  final int activeGoals, businesses, products, creatorDrafts, posts;
  final List<String> goalTitles, businessNames, productNames, draftTitles;
  final int averageGoalProgress;

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
    required this.averageGoalProgress,
  });

  String get nextMove {
    if (activeGoals == 0) return 'ابدأ هدفًا واحدًا في Personal AI ثم حوّله إلى خطوة عملية.';
    if (products == 0 && businesses > 0) return 'أضف أول منتج أو خدمة إلى Marketplace من Business.';
    if (creatorDrafts == 0) return 'حوّل هدفك أو خبرتك إلى أول مسودة محتوى في Creator Studio.';
    if (posts == 0) return 'انشر أول فكرة أو فرصة في Pulse وابنِ اتصالًا حولها.';
    if (averageGoalProgress < 50) return 'ارجع للهدف النشط ونفّذ خطوة صغيرة ترفع تقدمه اليوم.';
    return 'اربط ما أنشأته بفرصة جديدة: محتوى، عميل، منتج أو شراكة.';
  }

  String toPrompt() => 'أنت AUREN AI. حلّل وضعي عبر الوحدات الخمس الأساسية واصنع لي خطوة عملية واحدة الآن.\n'
      'Personal AI: $activeGoals أهداف نشطة (متوسط التقدم $averageGoalProgress%)${goalTitles.isEmpty ? '' : ' — ${goalTitles.join('، ')}'}.\n'
      'Social / Pulse: $posts منشورًا.\n'
      'Business: $businesses أنشطة${businessNames.isEmpty ? '' : ' — ${businessNames.join('، ')}'}.\n'
      'Marketplace: $products منتجات/خدمات${productNames.isEmpty ? '' : ' — ${productNames.join('، ')}'}.\n'
      'Creator Studio: $creatorDrafts مسودات${draftTitles.isEmpty ? '' : ' — ${draftTitles.join('، ')}'}.\n'
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
      averageGoalProgress: goals.isEmpty ? 0 : goals.fold<int>(0, (sum, d) => sum + ((d.data()['progress'] as num?)?.toInt() ?? 0)) ~/ goals.length,
    );
  }
}
