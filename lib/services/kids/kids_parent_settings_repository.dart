import 'package:cloud_firestore/cloud_firestore.dart';

class KidsParentSettings {
  final int ageBand;
  final bool aiTutor;
  final bool externalLinks;
  final int dailyMinutes;

  const KidsParentSettings({required this.ageBand, required this.aiTutor, required this.externalLinks, required this.dailyMinutes});

  factory KidsParentSettings.fromMap(Map<String, dynamic> data) {
    final age = (data['ageBand'] as num?)?.toInt() ?? 6;
    final minutes = (data['dailyMinutes'] as num?)?.toInt() ?? 60;
    return KidsParentSettings(
      ageBand: [6, 9, 13].contains(age) ? age : 6,
      aiTutor: data['aiTutor'] != false,
      externalLinks: data['externalLinks'] == true,
      dailyMinutes: [15, 30, 60, 90, 120, 180, 240].contains(minutes) ? minutes : 60,
    );
  }
}

class KidsParentSettingsRepository {
  final FirebaseFirestore db;
  KidsParentSettingsRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      db.collection('users').doc(uid).collection('kids').doc('parent_settings');

  Stream<KidsParentSettings> watch(String uid) => _ref(uid).snapshots().map(
        (snap) => KidsParentSettings.fromMap(snap.data() ?? const {}),
      );

  Future<void> save(String uid, {required int ageBand, required bool aiTutor, required bool externalLinks, required int dailyMinutes}) async {
    if (uid.trim().isEmpty) throw ArgumentError('المستخدم غير صالح');
    if (![6, 9, 13].contains(ageBand)) throw ArgumentError('الفئة العمرية غير صالحة');
    if (![15, 30, 60, 90, 120, 180, 240].contains(dailyMinutes)) throw ArgumentError('الحد اليومي غير صالح');
    await _ref(uid).set({
      'ageBand': ageBand,
      'aiTutor': aiTutor,
      'externalLinks': externalLinks,
      'dailyMinutes': dailyMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
