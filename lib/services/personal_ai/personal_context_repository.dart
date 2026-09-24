import 'package:cloud_firestore/cloud_firestore.dart';

class AurenPersonalContext {
  final List<AurenPersonalGoalContext> goals;
  final List<AurenPersonalMemoryContext> memories;

  const AurenPersonalContext({required this.goals, required this.memories});

  int get averageProgress => goals.isEmpty
      ? 0
      : goals.map((g) => g.progress).reduce((a, b) => a + b) ~/ goals.length;

  String toPrompt() {
    final goalsText = goals.isEmpty
        ? 'لا توجد أهداف نشطة.'
        : goals.map((g) => '- ${g.title} (${g.progress}%): ${g.description}').join('\n');
    final memoryText = memories.isEmpty
        ? 'لا توجد ذكريات مفعّلة.'
        : memories.map((m) => '- ${m.key}: ${m.value}').join('\n');
    return 'سياق Personal AI الحالي في AUREN:\n'
        'الأهداف النشطة:\n$goalsText\n'
        'الذاكرة المفعّلة:\n$memoryText\n'
        'استخدم هذا السياق كمعلومات مساعدة، ولا تنفذ أي إجراء بدون موافقة المستخدم.';
  }
}

class AurenPersonalGoalContext {
  final String id;
  final String title;
  final String description;
  final int progress;

  const AurenPersonalGoalContext({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
  });
}

class AurenPersonalMemoryContext {
  final String id;
  final String key;
  final String value;

  const AurenPersonalMemoryContext({
    required this.id,
    required this.key,
    required this.value,
  });
}

class PersonalContextRepository {
  final FirebaseFirestore _db;
  PersonalContextRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<AurenPersonalContext> load(String uid) async {
    final results = await Future.wait([
      _db.collection('users').doc(uid).collection('goals').limit(50).get(),
      _db.collection('users').doc(uid).collection('memory')
          .where('enabled', isEqualTo: true).limit(50).get(),
    ]);

    final goalsSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final memorySnap = results[1] as QuerySnapshot<Map<String, dynamic>>;

    final goals = goalsSnap.docs
        .map((d) {
          final data = d.data();
          final rawProgress = data['progress'];
          final progress = rawProgress is num
              ? rawProgress.toInt().clamp(0, 100)
              : 0;
          return AurenPersonalGoalContext(
            id: d.id,
            title: (data['title']?.toString() ?? '').trim(),
            description: (data['description']?.toString() ?? '').trim(),
            progress: progress,
          );
        })
        .where((g) =>
            g.title.isNotEmpty &&
            ((goalsSnap.docs.firstWhere((d) => d.id == g.id).data()['status']?.toString() ?? 'active') == 'active'))
        .take(10)
        .toList();

    final memories = memorySnap.docs.map((d) {
      final data = d.data();
      return AurenPersonalMemoryContext(
        id: d.id,
        key: (data['key']?.toString() ?? '').trim(),
        value: (data['value']?.toString() ?? '').trim(),
      );
    }).where((m) => m.key.isNotEmpty && m.value.isNotEmpty).take(20).toList();

    return AurenPersonalContext(goals: goals, memories: memories);
  }
}
