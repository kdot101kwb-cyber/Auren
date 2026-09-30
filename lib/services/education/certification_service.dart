import 'package:cloud_firestore/cloud_firestore.dart';

class CertificationService {
  final FirebaseFirestore _db;
  CertificationService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> _ref(String uid) => _db.collection('users').doc(uid).collection('certifications');
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyCertifications(String uid) => _ref(uid).orderBy('updatedAt', descending: true).snapshots();
  Future<void> saveCertification({required String uid, required String provider, required String name, required String area, String status = 'planned'}) async {
    final id = '${provider}_${name}'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    await _ref(uid).doc(id).set({'provider': provider, 'name': name, 'area': area, 'status': status, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }
  Future<void> updateStatus({required String uid, required String certificationId, required String status, double? score}) async {
    final data = <String, dynamic>{'status': status, 'updatedAt': FieldValue.serverTimestamp()};
    if (score != null) data['score'] = score;
    await _ref(uid).doc(certificationId).set(data, SetOptions(merge: true));
  }
}
