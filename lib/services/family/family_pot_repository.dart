import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyPotRepository {
  FamilyPotRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<Map<String, dynamic>>> watchMembers(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return _db.collection('users').doc(uid).collection('familyMembers')
        .orderBy('createdAt').limit(20).snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> watchPot(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return _db.collection('users').doc(uid).collection('familyPot')
        .orderBy('createdAt', descending: true).limit(50).snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> addMember({
    required String uid,
    required String name,
    required String relation,
  }) async {
    if (uid.isEmpty || name.trim().isEmpty || name.length > 120 ||
        relation.length > 80) {
      throw ArgumentError('بيانات عضو الأسرة غير صالحة.');
    }
    final ref = _db.collection('users').doc(uid).collection('familyMembers').doc();
    await ref.set({
      'name': name.trim(),
      'relation': relation.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addPotEntry({
    required String uid,
    required String title,
    required int amountMinor,
    required String currency,
  }) async {
    if (uid.isEmpty || title.trim().isEmpty || title.length > 160 ||
        amountMinor < 0 || amountMinor > 1000000000000 || currency.length != 3) {
      throw ArgumentError('بيانات صندوق الأسرة غير صالحة.');
    }
    final ref = _db.collection('users').doc(uid).collection('familyPot').doc();
    await ref.set({
      'title': title.trim(),
      'amountMinor': amountMinor,
      'currency': currency.toUpperCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMember(String uid, String memberId) async {
    if (uid.isEmpty || memberId.isEmpty) throw ArgumentError('معرّف غير صالح.');
    await _db.collection('users').doc(uid).collection('familyMembers').doc(memberId).delete();
  }
}
