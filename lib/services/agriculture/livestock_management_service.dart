import 'package:cloud_firestore/cloud_firestore.dart';

class LivestockAnimal {
  final String id;
  final String tag;
  final String species;
  final String status;
  final double? weightKg;
  const LivestockAnimal({required this.id, required this.tag, required this.species, required this.status, this.weightKg});

  factory LivestockAnimal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final weight = d['weightKg'];
    return LivestockAnimal(id: doc.id, tag: (d['tag'] ?? doc.id).toString(), species: (d['species'] ?? 'cattle').toString(), status: (d['status'] ?? 'active').toString(), weightKg: weight is num ? weight.toDouble() : null);
  }
}

class LivestockManagementService {
  final FirebaseFirestore db;
  LivestockManagementService({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _animals(String uid) => db.collection('users').doc(uid).collection('livestock');

  Stream<List<LivestockAnimal>> watchAnimals(String uid) => _animals(uid).snapshots().map((s) => s.docs.map(LivestockAnimal.fromDoc).toList());

  Future<String> addAnimal(String uid, {required String tag, required String species, double? weightKg, String status = 'active'}) async {
    if (uid.trim().isEmpty) throw ArgumentError('معرّف المستخدم مطلوب.');
    if (tag.trim().isEmpty || species.trim().isEmpty) throw ArgumentError('بيانات الحيوان غير مكتملة.');
    final ref = _animals(uid).doc();
    await ref.set({'tag': tag.trim(), 'species': species.trim(), 'weightKg': weightKg, 'status': status, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> updateWeight(String uid, String animalId, double weightKg) async {
    if (!weightKg.isFinite || weightKg <= 0) throw ArgumentError('الوزن غير صالح.');
    await _animals(uid).doc(animalId).update({'weightKg': weightKg, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> archive(String uid, String animalId) => _animals(uid).doc(animalId).update({'status': 'archived', 'updatedAt': FieldValue.serverTimestamp()});
}
