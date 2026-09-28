import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AurenAgricultureRecord {
  final String id;
  final String type;
  final String title;
  final String location;
  final String status;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic> data;

  const AurenAgricultureRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.location,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.data,
  });

  factory AurenAgricultureRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return AurenAgricultureRecord(
      id: doc.id,
      type: (d['type'] ?? 'crop').toString(),
      title: (d['title'] ?? 'Agriculture record').toString(),
      location: (d['location'] ?? '').toString(),
      status: (d['status'] ?? 'active').toString(),
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      data: d,
    );
  }
}

class AurenAgricultureRepository {
  final FirebaseFirestore db;
  AurenAgricultureRepository({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AurenAgricultureRecord>> watchRecords({
    String? type,
    String? location,
  }) {
    Query<Map<String, dynamic>> q = db.collection('agriculture_records')
        .where('visibility', isEqualTo: 'public')
        .limit(100);
    if (type != null && type.isNotEmpty) q = q.where('type', isEqualTo: type);
    return q.snapshots().map((s) {
      final needle = (location ?? '').trim().toLowerCase();
      final rows = s.docs.map(AurenAgricultureRecord.fromDoc).toList();
      if (needle.isEmpty) return rows;
      return rows.where((r) => r.location.toLowerCase().contains(needle)).toList();
    });
  }

  Stream<List<AurenAgricultureRecord>> watchOpportunities() {
    return db.collection('agriculture_opportunities')
        .where('visibility', isEqualTo: 'public')
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(AurenAgricultureRecord.fromDoc).toList());
  }

  Future<String> requestAiAdvice({
    required String type,
    required String observations,
    String location = '',
    String crop = '',
    String animal = '',
  }) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('aurenAgricultureAdvisor')
        .call({
      'type': type,
      'location': location.trim(),
      'crop': crop.trim(),
      'animal': animal.trim(),
      'observations': observations.trim(),
    });
    return (result.data is Map ? (result.data['advice'] ?? '') : '').toString();
  }

  Future<String> saveFieldNote({
    required String uid,
    required String title,
    required String note,
    required String type,
  }) async {
    final ref = db.collection('users').doc(uid).collection('agricultureNotes').doc();
    await ref.set({
      'title': title.trim(),
      'note': note.trim(),
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
