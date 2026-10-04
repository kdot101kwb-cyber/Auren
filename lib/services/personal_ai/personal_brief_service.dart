import 'package:cloud_firestore/cloud_firestore.dart';

class AurenPersonalBrief {
  final String title;
  final String summary;
  final List<String> priorities;
  final int activeGoals;
  final int averageProgress;
  final int enabledMemories;
  final DateTime generatedAt;

  const AurenPersonalBrief({
    required this.title,
    required this.summary,
    required this.priorities,
    required this.activeGoals,
    required this.averageProgress,
    required this.enabledMemories,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'summary': summary,
    'priorities': priorities,
    'activeGoals': activeGoals,
    'averageProgress': averageProgress,
    'enabledMemories': enabledMemories,
    'generatedAt': Timestamp.fromDate(generatedAt.toUtc()),
  };
}

class PersonalBriefService {
  final FirebaseFirestore _db;
  PersonalBriefService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  Future<AurenPersonalBrief> build(String uid) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) throw ArgumentError('uid is required');

    final results = await Future.wait([
      _db.collection('users').doc(cleanUid).collection('goals').get(),
      _db.collection('users').doc(cleanUid).collection('memory')
          .where('enabled', isEqualTo: true).limit(100).get(),
    ]);

    final goals = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final memories = results[1] as QuerySnapshot<Map<String, dynamic>>;

    final active = goals.docs.where((d) => (d.data()['status']?.toString() ?? 'active') == 'active').toList();
    final progressValues = active.map((d) => ((d.data()['progress'] as num?)?.toInt() ?? 0).clamp(0, 100)).toList();
    final average = progressValues.isEmpty ? 0 : progressValues.reduce((a, b) => a + b) ~/ progressValues.length;

    final priorities = active
        .map((d) => d.data()['title']?.toString().trim() ?? '')
        .where((x) => x.isNotEmpty)
        .take(5)
        .toList();

    final summary = active.isEmpty
        ? 'ما عندك أهداف نشطة حالياً. ابدأ بهدف واحد واضح.'
        : 'عندك ${active.length} أهداف نشطة، ومتوسط التقدم ${average}%. ركّز على أقرب خطوة قابلة للتنفيذ.';

    final brief = AurenPersonalBrief(
      title: 'AUREN Personal Brief',
      summary: summary,
      priorities: priorities,
      activeGoals: active.length,
      averageProgress: average,
      enabledMemories: memories.size,
      generatedAt: DateTime.now().toUtc(),
    );

    await _db.collection('users').doc(cleanUid).collection('personal_briefs').doc('current').set(brief.toMap());
    return brief;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String uid) =>
      _db.collection('users').doc(uid).collection('personal_briefs').doc('current').snapshots();
}