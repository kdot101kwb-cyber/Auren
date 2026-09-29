import 'package:cloud_firestore/cloud_firestore.dart';

class LivestockFeedPlan {
  final String species;
  final String stage;
  final double bodyWeightKg;
  final double dryMatterPercent;
  final double dailyFeedKg;
  final double dailyWaterLiters;
  final String note;

  const LivestockFeedPlan({
    required this.species,
    required this.stage,
    required this.bodyWeightKg,
    required this.dryMatterPercent,
    required this.dailyFeedKg,
    required this.dailyWaterLiters,
    required this.note,
  });
}

class LivestockPlanningService {
  final FirebaseFirestore db;
  LivestockPlanningService({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _plans(String uid) =>
      db.collection('users').doc(uid).collection('livestockFeedPlans');

  CollectionReference<Map<String, dynamic>> _schedules(String uid) =>
      db.collection('users').doc(uid).collection('livestockSchedules');

  LivestockFeedPlan estimateFeed({
    required String species,
    required double bodyWeightKg,
    String stage = 'maintenance',
  }) {
    final base = <String, double>{
      'cattle': 2.5,
      'sheep': 3.0,
      'goats': 3.0,
      'camels': 2.5,
      'poultry': 4.0,
    }[species] ?? 2.5;
    final stageFactor = <String, double>{
      'growth': 1.15,
      'fattening': 1.25,
      'pregnancy': 1.10,
      'lactation': 1.30,
      'maintenance': 1.00,
    }[stage] ?? 1.00;
    final dm = base * stageFactor;
    final feedKg = bodyWeightKg * dm / 100.0;
    final waterMultiplier = species == 'poultry' ? 2.0 : 2.5;
    final waterLiters = feedKg * waterMultiplier;
    return LivestockFeedPlan(
      species: species,
      stage: stage,
      bodyWeightKg: bodyWeightKg,
      dryMatterPercent: dm,
      dailyFeedKg: feedKg,
      dailyWaterLiters: waterLiters,
      note: 'تقدير تخطيطي مبسط؛ يختلف الاحتياج حسب العمر والسلالة والطقس ونوع العلف والإنتاج. لا يُستخدم كبديل عن إرشاد بيطري أو تغذوي متخصص.',
    );
  }

  Future<String> saveFeedPlan(
    String uid, {
    required String animalId,
    required LivestockFeedPlan plan,
  }) async {
    final ref = _plans(uid).doc();
    await ref.set({
      'animalId': animalId,
      'species': plan.species,
      'stage': plan.stage,
      'bodyWeightKg': plan.bodyWeightKg,
      'dryMatterPercent': plan.dryMatterPercent,
      'dailyFeedKg': plan.dailyFeedKg,
      'dailyWaterLiters': plan.dailyWaterLiters,
      'note': plan.note,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<String> addSchedule(
    String uid, {
    required String animalId,
    required String type,
    required String title,
    required DateTime dueAt,
    String note = '',
  }) async {
    final ref = _schedules(uid).doc();
    await ref.set({
      'animalId': animalId,
      'type': type,
      'title': title.trim(),
      'note': note.trim(),
      'dueAt': Timestamp.fromDate(dueAt),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchDueSchedules(
    String uid, {
    int limit = 50,
  }) =>
      _schedules(uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('dueAt')
          .limit(limit)
          .snapshots();

  Future<void> completeSchedule(String uid, String scheduleId) =>
      _schedules(uid).doc(scheduleId).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
