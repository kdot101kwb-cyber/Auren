import 'package:cloud_firestore/cloud_firestore.dart';

class AurenTravelPlan {
  final String id, ownerId, title, destination, country, status, notes;
  final DateTime? startDate, endDate, createdAt;
  final int travelers;
  const AurenTravelPlan({required this.id, required this.ownerId, required this.title, required this.destination, required this.country, required this.startDate, required this.endDate, required this.travelers, required this.status, required this.notes, required this.createdAt});
  factory AurenTravelPlan.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? date(dynamic v) => v is Timestamp ? v.toDate() : null;
    return AurenTravelPlan(id: doc.id, ownerId: (d['ownerId'] ?? '') as String, title: (d['title'] ?? '') as String, destination: (d['destination'] ?? '') as String, country: (d['country'] ?? '') as String, startDate: date(d['startDate']), endDate: date(d['endDate']), travelers: (d['travelers'] ?? 1) as int, status: (d['status'] ?? 'planned') as String, notes: (d['notes'] ?? '') as String, createdAt: date(d['createdAt']));
  }
}

class AurenTravelService {
  AurenTravelService._();
  static final instance = AurenTravelService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> _plans(String uid) => _db.collection('users').doc(uid).collection('travel_plans');
  Stream<List<AurenTravelPlan>> watchPlans(String uid) => _plans(uid).orderBy('startDate').limit(50).snapshots().map((s) => s.docs.map(AurenTravelPlan.fromDoc).toList());
  Future<String> createPlan({required String uid, required String title, required String destination, required String country, DateTime? startDate, DateTime? endDate, int travelers=1, String notes=''}) async {
    if (uid.isEmpty || title.trim().isEmpty || destination.trim().isEmpty || country.trim().isEmpty) throw ArgumentError('بيانات الرحلة الأساسية مطلوبة.');
    if (travelers < 1 || travelers > 50) throw ArgumentError('عدد المسافرين يجب أن يكون بين 1 و50.');
    if (startDate != null && endDate != null && endDate.isBefore(startDate)) throw ArgumentError('تاريخ العودة لا يمكن أن يسبق تاريخ المغادرة.');
    if (notes.length > 2000) throw ArgumentError('الملاحظات طويلة جداً.');
    final ref = _plans(uid).doc();
    await ref.set({'ownerId':uid,'title':title.trim(),'destination':destination.trim(),'country':country.trim(),'startDate':startDate == null ? null : Timestamp.fromDate(startDate),'endDate':endDate == null ? null : Timestamp.fromDate(endDate),'travelers':travelers,'status':'planned','notes':notes.trim(),'createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});
    return ref.id;
  }
  Future<void> updateStatus(String uid,String planId,String status) async {
    if (!['planned','active','completed','cancelled'].contains(status)) throw ArgumentError('حالة الرحلة غير صالحة.');
    await _plans(uid).doc(planId).update({'status':status,'updatedAt':FieldValue.serverTimestamp()});
  }
  Future<void> deletePlan(String uid,String planId) => _plans(uid).doc(planId).delete();
}