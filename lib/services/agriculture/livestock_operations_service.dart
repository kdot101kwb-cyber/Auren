import 'package:cloud_firestore/cloud_firestore.dart';

class LivestockAnalytics {
  final int activeAnimals;
  final int totalAnimals;
  final double averageWeightKg;
  final double weightChangeKg;
  final double productionToday;
  final int dueAlerts;
  const LivestockAnalytics({
    required this.activeAnimals,
    required this.totalAnimals,
    required this.averageWeightKg,
    required this.weightChangeKg,
    required this.productionToday,
    required this.dueAlerts,
  });
}

class LivestockProductionRecord {
  final String animalId;
  final String type;
  final double quantity;
  final String unit;
  final DateTime recordedAt;
  final String note;
  const LivestockProductionRecord({
    required this.animalId,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.recordedAt,
    this.note = '',
  });
}

class LivestockGrowthRecord {
  final String animalId;
  final double weightKg;
  final DateTime recordedAt;
  const LivestockGrowthRecord({
    required this.animalId,
    required this.weightKg,
    required this.recordedAt,
  });
}

class LivestockOperationsService {
  final FirebaseFirestore db;
  LivestockOperationsService({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _production(String uid) =>
      db.collection('users').doc(uid).collection('livestockProduction');
  CollectionReference<Map<String, dynamic>> _growth(String uid) =>
      db.collection('users').doc(uid).collection('livestockGrowth');
  CollectionReference<Map<String, dynamic>> _alerts(String uid) =>
      db.collection('users').doc(uid).collection('livestockAlerts');

  Future<String> recordProduction(
    String uid, {
    required String animalId,
    required String type,
    required double quantity,
    required String unit,
    String note = '',
    DateTime? recordedAt,
  }) async {
    if (quantity < 0) throw ArgumentError('quantity must be non-negative');
    final ref = _production(uid).doc();
    await ref.set({
      'animalId': animalId,
      'type': type,
      'quantity': quantity,
      'unit': unit,
      'note': note.trim(),
      'recordedAt': Timestamp.fromDate(recordedAt ?? DateTime.now()),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProduction(
    String uid, {
    String? animalId,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> q = _production(uid).orderBy('recordedAt', descending: true);
    if (animalId != null) q = q.where('animalId', isEqualTo: animalId);
    return q.limit(limit).snapshots();
  }

  Future<String> recordGrowth(
    String uid, {
    required String animalId,
    required double weightKg,
    DateTime? recordedAt,
  }) async {
    if (weightKg <= 0) throw ArgumentError('weightKg must be positive');
    final ref = _growth(uid).doc();
    await ref.set({
      'animalId': animalId,
      'weightKg': weightKg,
      'recordedAt': Timestamp.fromDate(recordedAt ?? DateTime.now()),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchGrowth(
    String uid, {
    String? animalId,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> q = _growth(uid).orderBy('recordedAt', descending: true);
    if (animalId != null) q = q.where('animalId', isEqualTo: animalId);
    return q.limit(limit).snapshots();
  }

  Future<String> createAlert(
    String uid, {
    required String animalId,
    required String type,
    required String title,
    required DateTime dueAt,
    String note = '',
  }) async {
    final ref = _alerts(uid).doc();
    await ref.set({
      'animalId': animalId,
      'type': type,
      'title': title.trim(),
      'note': note.trim(),
      'dueAt': Timestamp.fromDate(dueAt),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAlerts(
    String uid, {
    int limit = 100,
  }) =>
      _alerts(uid)
          .where('status', isEqualTo: 'open')
          .orderBy('dueAt')
          .limit(limit)
          .snapshots();

  Future<void> closeAlert(String uid, String alertId) =>
      _alerts(uid).doc(alertId).update({
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
      });

  Future<void> bulkUpdateAnimals(
    String uid, {
    required List<String> animalIds,
    String? status,
    double? weightKg,
  }) async {
    if (animalIds.isEmpty) return;
    final batch = db.batch();
    for (final id in animalIds) {
      final ref = db.collection('users').doc(uid).collection('livestockAnimals').doc(id);
      final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
      if (status != null) data['status'] = status;
      if (weightKg != null) data['weightKg'] = weightKg;
      batch.update(ref, data);
    }
    await batch.commit();
  }

  Future<LivestockAnalytics> calculateAnalytics(
    String uid,
    List<Map<String, dynamic>> animals,
  ) async {
    final active = animals.where((a) => a['status'] == 'active').toList();
    final weights = active
        .map((a) => (a['weightKg'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final avg = weights.isEmpty ? 0 : weights.reduce((a, b) => a + b) / weights.length;

    final growth = await _growth(uid).orderBy('recordedAt', descending: true).limit(200).get();
    double change = 0;
    final latestByAnimal = <String, double>{};
    for (final d in growth.docs) {
      final data = d.data();
      final id = data['animalId']?.toString();
      final w = (data['weightKg'] as num?)?.toDouble();
      if (id != null && w != null) latestByAnimal.putIfAbsent(id, () => w);
    }
    for (final a in active) {
      final id = a['id']?.toString();
      final current = (a['weightKg'] as num?)?.toDouble();
      final previous = id == null ? null : latestByAnimal[id];
      if (current != null && previous != null) change += current - previous;
    }

    final start = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)));
    final production = await _production(uid).where('recordedAt', isGreaterThanOrEqualTo: start).get();
    final total = production.docs.fold<double>(0, (sum, d) {
      return sum + ((d.data()['quantity'] as num?)?.toDouble() ?? 0);
    });
    final alerts = await _alerts(uid).where('status', isEqualTo: 'open').get();

    return LivestockAnalytics(
      activeAnimals: active.length,
      totalAnimals: animals.length,
      averageWeightKg: avg,
      weightChangeKg: change,
      productionToday: total,
      dueAlerts: alerts.docs.length,
    );
  }
}
