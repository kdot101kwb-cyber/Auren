import 'package:cloud_firestore/cloud_firestore.dart';

class AurenHealthCheckin {
  const AurenHealthCheckin({
    required this.id,
    required this.activityMinutes,
    required this.waterGlasses,
    required this.sleepHours,
    required this.mood,
    required this.updatedAt,
  });

  final String id;
  final int activityMinutes;
  final int waterGlasses;
  final double sleepHours;
  final int mood;
  final DateTime? updatedAt;

  factory AurenHealthCheckin.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return AurenHealthCheckin(
      id: doc.id,
      activityMinutes: (d['activityMinutes'] as num?)?.toInt() ?? 0,
      waterGlasses: (d['waterGlasses'] as num?)?.toInt() ?? 0,
      sleepHours: (d['sleepHours'] as num?)?.toDouble() ?? 0,
      mood: (d['mood'] as num?)?.toInt() ?? 3,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class AurenHealthRepository {
  AurenHealthRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<AurenHealthCheckin>> watchCheckins(String uid) {
    if (uid.trim().isEmpty) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('healthCheckins')
        .orderBy('updatedAt', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map(AurenHealthCheckin.fromDoc).toList());
  }

  Future<void> saveCheckin({
    required String uid,
    required String dateId,
    required int activityMinutes,
    required int waterGlasses,
    required double sleepHours,
    required int mood,
  }) async {
    if (uid.trim().isEmpty || dateId.trim().isEmpty) {
      throw ArgumentError('uid و dateId مطلوبان');
    }
    if (activityMinutes < 0 || activityMinutes > 1440 ||
        waterGlasses < 0 || waterGlasses > 50 ||
        sleepHours < 0 || sleepHours > 24 ||
        mood < 1 || mood > 5) {
      throw ArgumentError('قيم المتابعة الصحية غير صالحة');
    }
    await _db.collection('users').doc(uid).collection('healthCheckins').doc(dateId).set({
      'activityMinutes': activityMinutes,
      'waterGlasses': waterGlasses,
      'sleepHours': sleepHours,
      'mood': mood,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
