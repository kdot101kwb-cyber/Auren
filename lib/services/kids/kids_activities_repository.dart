import 'package:cloud_firestore/cloud_firestore.dart';

class KidsActivity {
  const KidsActivity({required this.id, required this.title, required this.description, required this.category, required this.minAge, required this.maxAge, required this.minutes});
  final String id, title, description, category;
  final int minAge, maxAge, minutes;
  factory KidsActivity.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return KidsActivity(id: doc.id, title: d['title'] as String? ?? '', description: d['description'] as String? ?? '', category: d['category'] as String? ?? 'learn', minAge: (d['minAge'] as num?)?.toInt() ?? 6, maxAge: (d['maxAge'] as num?)?.toInt() ?? 17, minutes: (d['minutes'] as num?)?.toInt() ?? 10);
  }
}
class KidsActivityProgress {
  const KidsActivityProgress(this.completedIds);
  final Set<String> completedIds;
}
class KidsActivitiesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Stream<List<KidsActivity>> watchActivities(int ageBand) => _db.collection('kids_activities').where('published', isEqualTo: true).where('minAge', isLessThanOrEqualTo: ageBand).orderBy('minAge').limit(50).snapshots().map((s) => s.docs.map(KidsActivity.fromFirestore).where((a) => ageBand <= a.maxAge).toList());
  Stream<KidsActivityProgress> watchProgress(String uid) => _db.collection('users').doc(uid).collection('kids_activity_progress').snapshots().map((s) => KidsActivityProgress(s.docs.where((d) => d.data()['completed'] == true).map((d) => d.id).toSet()));
  Future<void> setCompleted({required String uid, required String activityId, required bool completed}) => _db.collection('users').doc(uid).collection('kids_activity_progress').doc(activityId).set({'activityId': activityId, 'completed': completed, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
}
