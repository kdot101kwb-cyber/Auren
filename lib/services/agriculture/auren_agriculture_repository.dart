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
    Query<Map<String, dynamic>> q = db
        .collection('agriculture_records')
        .where('visibility', isEqualTo: 'public')
        .limit(100);
    if (type != null && type.isNotEmpty) {
      q = q.where('type', isEqualTo: type);
    }
    return q.snapshots().map((s) {
      final needle = (location ?? '').trim().toLowerCase();
      final rows = s.docs.map(AurenAgricultureRecord.fromDoc).toList();
      if (needle.isEmpty) return rows;
      return rows
          .where((r) => r.location.toLowerCase().contains(needle))
          .toList();
    });
  }

  Stream<List<AurenAgricultureRecord>> watchOpportunities() {
    return db
        .collection('agriculture_opportunities')
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
    String material = '',
    String invention = '',
  }) async {
    const supportedTypes = {
      'crop',
      'livestock',
      'farm',
      'manufacturing',
      'invention',
      'research',
      'energy',
      'recycling',
      'design',
      'business',
      'production',
      'costing',
      'supply_chain',
      'quality',
      'feasibility',
    };
    final cleanType = supportedTypes.contains(type) ? type : 'crop';
    final cleanObservations = observations.trim();

    if (cleanObservations.isEmpty || cleanObservations.length > 5000) {
      throw ArgumentError(
        'الملاحظات مطلوبة وبحد أقصى 5000 حرف.',
      );
    }
    for (final value in [location, crop, animal, material, invention]) {
      if (value.trim().length > 160) {
        throw ArgumentError('أحد الحقول أطول من المسموح.');
      }
    }

    final result = await FirebaseFunctions.instance
        .httpsCallable('aurenAgricultureAdvisor')
        .call({
      'type': cleanType,
      'location': location.trim(),
      'crop': crop.trim(),
      'animal': animal.trim(),
      'material': material.trim(),
      'invention': invention.trim(),
      'observations': cleanObservations,
    });

    return (result.data is Map ? (result.data['advice'] ?? '') : '').toString();
  }

  Future<String> saveFieldNote({
    required String uid,
    required String title,
    required String note,
    required String type,
  }) async {
    final cleanUid = uid.trim();
    final cleanTitle = title.trim();
    final cleanNote = note.trim();
    final cleanType = type.trim();

    if (cleanUid.isEmpty || cleanUid.length > 128) {
      throw ArgumentError('معرّف المستخدم غير صالح.');
    }
    if (cleanTitle.isEmpty ||
        cleanTitle.length > 160 ||
        cleanNote.isEmpty ||
        cleanNote.length > 5000) {
      throw ArgumentError('عنوان الملاحظة ونصها مطلوبان وبطول مناسب.');
    }

    const allowedNoteTypes = {
      'crop',
      'livestock',
      'soil',
      'pest',
      'irrigation',
      'general',
      'field',
      'farm',
      'manufacturing',
      'invention',
      'research',
      'energy',
      'recycling',
      'design',
      'business',
      'production',
      'costing',
      'supply_chain',
      'quality',
      'feasibility',
    };
    if (!allowedNoteTypes.contains(cleanType)) {
      throw ArgumentError('نوع الملاحظة غير صالح.');
    }

    final ref = db
        .collection('users')
        .doc(cleanUid)
        .collection('agricultureNotes')
        .doc();
    await ref.set({
      'title': cleanTitle,
      'note': cleanNote,
      'type': cleanType,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
