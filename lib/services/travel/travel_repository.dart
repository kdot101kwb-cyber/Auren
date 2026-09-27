import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/travel.dart';

class TravelRepository {
  final FirebaseFirestore db;
  TravelRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  void _requireUid(String uid) {
    if (uid.trim().isEmpty) throw ArgumentError.value(uid, 'uid', 'must not be empty');
  }

  Stream<List<AurenPlace>> watchPlaces() => db.collection('places').where('visibility', isEqualTo: 'public').limit(100).snapshots().map(
        (s) => s.docs.map((d) => AurenPlace.fromMap(d.id, d.data())).toList(),
      );

  Stream<Set<String>> watchSavedIds(String uid) {
    _requireUid(uid);
    return db.collection('users').doc(uid).collection('savedPlaces').snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  }

  Future<void> toggleSaved(String uid, String placeId, bool saved) {
    _requireUid(uid);
    if (placeId.trim().isEmpty) throw ArgumentError.value(placeId, 'placeId', 'must not be empty');
    final ref = db.collection('users').doc(uid).collection('savedPlaces').doc(placeId);
    return saved ? ref.set({'placeId': placeId, 'createdAt': FieldValue.serverTimestamp()}) : ref.delete();
  }

  Stream<List<AurenPlace>> watchSavedPlaces(String uid) {
    _requireUid(uid);
    return db.collection('users').doc(uid).collection('savedPlaces').snapshots().asyncMap((s) async {
      final out = <AurenPlace>[];
      for (final d in s.docs) {
        final p = await db.collection('places').doc(d.id).get();
        if (p.exists && p.data()?['visibility'] == 'public') out.add(AurenPlace.fromMap(p.id, p.data()!));
      }
      return out;
    });
  }

  Future<String> createTrip({
    required String uid,
    required String title,
    required String destination,
    DateTime? startDate,
    DateTime? endDate,
    int travelers = 1,
    List<String> placeIds = const [],
  }) async {
    _requireUid(uid);
    final cleanTitle = title.trim();
    final cleanDestination = destination.trim();
    if (cleanTitle.isEmpty || cleanDestination.isEmpty) throw ArgumentError('عنوان الرحلة والوجهة مطلوبان.');
    if (cleanTitle.length > 160 || cleanDestination.length > 160) throw ArgumentError('بيانات الرحلة طويلة جداً.');
    if (travelers < 1 || travelers > 50) throw ArgumentError('عدد المسافرين يجب أن يكون بين 1 و50.');
    if (startDate != null && endDate != null && endDate.isBefore(startDate)) throw ArgumentError('تاريخ العودة لا يمكن أن يسبق تاريخ الذهاب.');
    final ids = placeIds.map((e) => e.trim()).where((e) => e.isNotEmpty).take(100).toSet().toList();
    final r = db.collection('trips').doc();
    await r.set({
      'ownerId': uid,
      'title': cleanTitle,
      'destination': cleanDestination,
      'startDate': startDate == null ? null : Timestamp.fromDate(startDate),
      'endDate': endDate == null ? null : Timestamp.fromDate(endDate),
      'travelers': travelers,
      'placeIds': ids,
      'status': 'planned',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return r.id;
  }

  Stream<List<AurenTrip>> watchMyTrips(String uid) {
    _requireUid(uid);
    return db.collection('trips').where('ownerId', isEqualTo: uid).limit(50).snapshots().map(
          (s) => s.docs.map((d) => AurenTrip.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> updateTripStatus(String uid, String tripId, String status) async {
    _requireUid(uid);
    if (!['planned', 'active', 'completed', 'cancelled'].contains(status)) throw ArgumentError('حالة الرحلة غير صالحة.');
    final ref = db.collection('trips').doc(tripId);
    final snap = await ref.get();
    if (!snap.exists || snap.data()?['ownerId'] != uid) throw StateError('لا يمكنك تعديل هذه الرحلة.');
    await ref.update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteTrip(String uid, String tripId) async {
    _requireUid(uid);
    final ref = db.collection('trips').doc(tripId);
    final snap = await ref.get();
    if (!snap.exists) return;
    if (snap.data()?['ownerId'] != uid) throw StateError('لا يمكنك حذف رحلة لا تملكها.');
    await ref.delete();
  }
}
