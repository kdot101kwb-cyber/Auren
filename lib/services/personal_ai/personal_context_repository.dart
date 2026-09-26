import 'dart:async';

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
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'must not be empty');
    }

    final results = await Future.wait([
      _db.collection('users').doc(cleanUid).collection('goals').limit(50).get(),
      _db.collection('users').doc(cleanUid).collection('memory')
          .where('enabled', isEqualTo: true).limit(50).get(),
    ]);

    return _fromSnapshots(
      results[0] as QuerySnapshot<Map<String, dynamic>>,
      results[1] as QuerySnapshot<Map<String, dynamic>>,
    );
  }

  Stream<AurenPersonalContext> watch(String uid) {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) {
      return Stream.error(
        ArgumentError.value(uid, 'uid', 'must not be empty'),
      );
    }

    late final StreamController<AurenPersonalContext> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? goalsSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? memorySub;
    QuerySnapshot<Map<String, dynamic>>? latestGoals;
    QuerySnapshot<Map<String, dynamic>>? latestMemory;

    Future<void> emitIfReady() async {
      final goals = latestGoals;
      final memory = latestMemory;
      if (goals == null || memory == null || controller.isClosed) return;
      controller.add(_fromSnapshots(goals, memory));
    }

    controller = StreamController<AurenPersonalContext>(
      onListen: () {
        final user = _db.collection('users').doc(cleanUid);

        goalsSub = user.collection('goals').limit(50).snapshots().listen((snapshot) {
          latestGoals = snapshot;
          emitIfReady();
        }, onError: controller.addError);

        memorySub = user
            .collection('memory')
            .where('enabled', isEqualTo: true)
            .limit(50)
            .snapshots()
            .listen((snapshot) {
          latestMemory = snapshot;
          emitIfReady();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await goalsSub?.cancel();
        await memorySub?.cancel();
      },
    );

    return controller.stream;
  }

  AurenPersonalContext _fromSnapshots(
    QuerySnapshot<Map<String, dynamic>> goalsSnap,
    QuerySnapshot<Map<String, dynamic>> memorySnap,
  ) {
    final goals = <AurenPersonalGoalContext>[];
    for (final doc in goalsSnap.docs) {
      final data = doc.data();
      final title = (data['title']?.toString() ?? '').trim();
      final status = (data['status']?.toString() ?? 'active').trim();
      if (title.isEmpty || status != 'active') continue;

      final rawProgress = data['progress'];
      final progress = rawProgress is num
          ? rawProgress.toInt().clamp(0, 100)
          : 0;

      goals.add(AurenPersonalGoalContext(
        id: doc.id,
        title: title,
        description: (data['description']?.toString() ?? '').trim(),
        progress: progress,
      ));
      if (goals.length == 10) break;
    }

    final memories = <AurenPersonalMemoryContext>[];
    for (final doc in memorySnap.docs) {
      final data = doc.data();
      final key = (data['key']?.toString() ?? '').trim();
      final value = (data['value']?.toString() ?? '').trim();
      if (key.isEmpty || value.isEmpty) continue;

      memories.add(AurenPersonalMemoryContext(
        id: doc.id,
        key: key,
        value: value,
      ));
      if (memories.length == 20) break;
    }

    return AurenPersonalContext(goals: goals, memories: memories);
  }
}
