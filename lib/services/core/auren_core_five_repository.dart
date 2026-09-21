import 'package:cloud_firestore/cloud_firestore.dart';

class AurenCoreFiveSnapshot {
  final int activeGoals, businesses, products, creatorDrafts, posts;
  final List<String> goalTitles, businessNames, productNames, draftTitles;
  const AurenCoreFiveSnapshot({required this.activeGoals, required this.businesses, required this.products, required this.creatorDrafts, required this.posts, required this.goalTitles, required this.businessNames, required this.productNames, required this.draftTitles});

  String toPrompt() => 'أنت AUREN AI. حلّل وضعي عبر الوحدات الخمس الأساسية واصنع لي خطوة عملية واحدة الآن.\\n'
      'Personal AI: $activeGoals أهداف نشطة${goalTitles.isEmpty ? '' : ' — ${goalTitles.join('، ')}'}.\\n'
      'Social / Pulse: $posts منشورًا.\\n'
      'Business: $businesses أنشطة${businessNames.isEmpty ? '' : ' — ${businessNames.join('، ')}'}.\\n'
      'Marketplace: $products منتجات/خدمات${productNames.isEmpty ? '' : ' — ${productNames.join('، ')}'}.\\n'
      'Creator Studio: $creatorDrafts مسودات${draftTitles.isEmpty ? '' : ' — ${draftTitles.join('، ')}'}.\\n'
      'اربط الوحدات ببعضها، وحوّل هدفي إلى محتوى أو فرصة أو منتج أو خطوة Business. أعطني الخطوة التالية القابلة للتنفيذ.';
}

class AurenCoreFiveRepository {
  final FirebaseFirestore db;
  AurenCoreFiveRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;
  Future<AurenCoreFiveSnapshot> load(String uid) async {
    final r = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
      db.collection('users').doc(uid).collection('goals').limit(50).get(),
      db.collection('businesses').where('ownerId', isEqualTo: uid).limit(50).get(),
      db.collection('products').where('ownerId', isEqualTo: uid).limit(100).get(),
      db.collection('creator_drafts').where('ownerId', isEqualTo: uid).limit(50).get(),
      db.collection('posts').where('authorId', isEqualTo: uid).limit(100).get(),
    ]);
    final goals = r[0].docs.where((d) => (d.data()['status']?.toString() ?? 'active') == 'active').toList();
    List<String> names(QuerySnapshot<Map<String, dynamic>> s, String key) => s.docs.map((d) => d.data()[key]?.toString().trim() ?? '').where((v) => v.isNotEmpty).take(5).toList();
    return AurenCoreFiveSnapshot(activeGoals: goals.length, businesses: r[1].docs.length, products: r[2].docs.length, creatorDrafts: r[3].docs.length, posts: r[4].docs.length, goalTitles: goals.map((d) => d.data()['title']?.toString().trim() ?? '').where((v) => v.isNotEmpty).take(5).toList(), businessNames: names(r[1], 'name'), productNames: names(r[2], 'name'), draftTitles: names(r[3], 'title'));
  }
}
