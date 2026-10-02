import 'package:cloud_firestore/cloud_firestore.dart';

class KidsActivity {
  const KidsActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.minAge,
    required this.maxAge,
    required this.minutes,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final int minAge;
  final int maxAge;
  final int minutes;

  factory KidsActivity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return KidsActivity(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'learn',
      minAge: (data['minAge'] as num?)?.toInt() ?? 6,
      maxAge: (data['maxAge'] as num?)?.toInt() ?? 17,
      minutes: (data['minutes'] as num?)?.toInt() ?? 10,
    );
  }
}

class KidsActivityProgress {
  const KidsActivityProgress(this.completedIds);

  final Set<String> completedIds;
}

class KidsActivitiesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<KidsActivity>> watchActivities(int ageBand) {
    if (![6, 9, 13].contains(ageBand)) {
      return const Stream<List<KidsActivity>>.empty();
    }

    return _db
        .collection('kids_activities')
        .where('published', isEqualTo: true)
        .where('minAge', isLessThanOrEqualTo: ageBand)
        .orderBy('minAge')
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(KidsActivity.fromFirestore)
              .where((activity) => ageBand <= activity.maxAge)
              .where(
                (activity) =>
                    activity.title.trim().isNotEmpty &&
                    activity.minutes >= 1 &&
                    activity.minutes <= 240,
              )
              .toList(),
        );
  }

  Stream<KidsActivityProgress> watchProgress(String uid) {
    if (uid.trim().isEmpty) {
      return Stream.value(const KidsActivityProgress(<String>{}));
    }

    return _db
        .collection('users')
        .doc(uid)
        .collection('kids_activity_progress')
        .snapshots()
        .map(
          (snapshot) => KidsActivityProgress(
            snapshot.docs
                .where(
                  (doc) =>
                      doc.data()['completed'] == true &&
                      doc.data()['activityId'] == doc.id,
                )
                .map((doc) => doc.id)
                .toSet(),
          ),
        );
  }

  Future<void> setCompleted({
    required String uid,
    required String activityId,
    required bool completed,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedActivityId = activityId.trim();

    if (normalizedUid.isEmpty || normalizedActivityId.isEmpty) {
      throw ArgumentError('بيانات النشاط غير صالحة');
    }

    final activity = await _db
        .collection('kids_activities')
        .doc(normalizedActivityId)
        .get();
    if (!activity.exists || activity.data()?['published'] != true) {
      throw StateError('النشاط غير متاح');
    }

    await _db
        .collection('users')
        .doc(normalizedUid)
        .collection('kids_activity_progress')
        .doc(normalizedActivityId)
        .set(
          {
            'activityId': normalizedActivityId,
            'completed': completed,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
  }
}
