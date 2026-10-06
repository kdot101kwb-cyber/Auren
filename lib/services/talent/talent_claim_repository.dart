import 'package:cloud_firestore/cloud_firestore.dart';

class TalentClaimRepository {
  final FirebaseFirestore db;
  TalentClaimRepository({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  Future<String> submit({
    required String talentId,
    required String claimantUid,
    required String evidence,
  }) async {
    final existing = await db.collection('talent_claims').where('talentId', isEqualTo: talentId).where('claimantUid', isEqualTo: claimantUid).where('status', isEqualTo: 'pending').limit(1).get();
    if (existing.docs.isNotEmpty) throw StateError('لديك طلب معلّق بالفعل لهذا الملف.');
    final ref = db.collection('talent_claims').doc();
    await ref.set({
      'talentId': talentId,
      'claimantUid': claimantUid,
      'evidence': evidence.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<Map<String, dynamic>>> watchMine(String uid) {
    return db
        .collection('talent_claims')
        .where('claimantUid', isEqualTo: uid)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return <String, dynamic>{'id': d.id, ...data};
            }).toList());
  }
}
