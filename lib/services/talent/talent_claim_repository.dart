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
    final cleanTalentId = talentId.trim();
    final cleanClaimantUid = claimantUid.trim();
    final cleanEvidence = evidence.trim();
    if (cleanTalentId.isEmpty || cleanClaimantUid.isEmpty || cleanEvidence.isEmpty) {
      throw ArgumentError('بيانات المطالبة غير مكتملة.');
    }
    if (cleanTalentId.length > 128 || cleanClaimantUid.length > 128) {
      throw ArgumentError('معرّف المطالبة طويل جدًا.');
    }
    if (cleanEvidence.length > 1200) {
      throw ArgumentError('الدليل يجب ألا يتجاوز 1200 حرف.');
    }

    final existing = await db
        .collection('talent_claims')
        .where('talentId', isEqualTo: cleanTalentId)
        .where('claimantUid', isEqualTo: cleanClaimantUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw StateError('لديك طلب معلّق بالفعل لهذا الملف.');
    }

    final ref = db.collection('talent_claims').doc();
    await ref.set({
      'talentId': cleanTalentId,
      'claimantUid': cleanClaimantUid,
      'evidence': cleanEvidence,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<Map<String, dynamic>>> watchMine(String uid) {
    return db
        .collection('talent_claims')
        .where('claimantUid', isEqualTo: uid.trim())
        .limit(50)
        .snapshots()
        .map((snap) {
          final claims = snap.docs.map((d) {
            final data = d.data();
            return <String, dynamic>{'id': d.id, ...data};
          }).toList();

          DateTime createdAt(Map<String, dynamic> claim) {
            final value = claim['createdAt'];
            if (value is Timestamp) return value.toDate();
            if (value is DateTime) return value;
            return DateTime.fromMillisecondsSinceEpoch(0);
          }

          claims.sort((a, b) => createdAt(b).compareTo(createdAt(a)));
          return claims;
        });
  }
}