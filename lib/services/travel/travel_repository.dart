import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/travel.dart';

class TravelRepository {
  void _requireUid(String uid) {
    if (uid.trim().isEmpty) throw ArgumentError.value(uid, 'uid', 'must not be empty');
  }
  final FirebaseFirestore db;
  TravelRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;
  Stream<List<AurenPlace>> watchPlaces() => db.collection('places').where('visibility', isEqualTo: 'public').limit(100).snapshots().map((s) => s.docs.map((d) => AurenPlace.fromMap(d.id, d.data())).toList());
  Stream<Set<String>> watchSavedIds(String uid) {
    _requireUid(uid);
    return db.collection('users').doc(uid).collection('savedPlaces').snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  }
  Future<String> createTrip({required String uid, required String title, required String destination, List<String> placeIds = const []}) async {
    _requireUid(uid);
    final cleanTitle = title.trim();
    final cleanDestination = destination.trim();
    if (cleanTitle.isEmpty) throw ArgumentError('عنوان الرحلة مطلوب.');
    if (cleanDestination.isEmpty) throw ArgumentError('وجهة الرحلة مطلوبة.');
    final ids = placeIds.map((e) => e.trim()).where((e) => e.isNotEmpty).take(100).toSet().toList();
    final r = db.collection('trips').doc();
    await r.set({'ownerId': uid, 'title': cleanTitle.length > 160 ? cleanTitle.substring(0,160) : cleanTitle, 'destination': cleanDestination.length > 160 ? cleanDestination.substring(0,160) : cleanDestination, 'placeIds': ids, 'createdAt': FieldValue.serverTimestamp()});
    return r.id;
  }
  Stream<List<AurenTrip>> watchMyTrips(String uid) {
    _requireUid(uid);
    return db.collection('trips').where('ownerId', isEqualTo: uid).snapshots().map((s) => s.docs.map((d) => AurenTrip.fromMap(d.id, d.data())).toList());
  Future<void> toggleSaved(String uid, String placeId, bool saved) { _requireUid(uid); if (placeId.trim().isEmpty) throw ArgumentError.value(placeId, 'placeId', 'must not be empty'); return saved ? db.collection('users').doc(uid).collection('savedPlaces').doc(placeId).set({'placeId': placeId, 'createdAt': FieldValue.serverTimestamp()}) : db.collection('users').doc(uid).collection('savedPlaces').doc(placeId).delete();
  Stream<List<AurenPlace>> watchSavedPlaces(String uid) { _requireUid(uid); return db.collection('users').doc(uid).collection('savedPlaces').snapshots().asyncMap((s) async { final out=<AurenPlace>[]; for(final d in s.docs){ final p=await db.collection('places').doc(d.id).get(); if(p.exists && (p.data()?['visibility']=='public')) out.add(AurenPlace.fromMap(p.id,p.data()!)); } return out; });
  Future<void> deleteTrip(String uid,String tripId) async {
    _requireUid(uid);
    final id = tripId.trim();
    if (id.isEmpty) throw ArgumentError.value(tripId, 'tripId', 'must not be empty');
    final ref = db.collection('trips').doc(id);
    final snap = await ref.get();
    if (!snap.exists) return;
    if (snap.data()?['ownerId'] != uid) throw StateError('لا يمكنك حذف رحلة لا تملكها.');
    await ref.delete();
  }
}
