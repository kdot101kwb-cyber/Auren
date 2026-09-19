import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class AurenPresenceService {
  final FirebaseFirestore _db;
  AurenPresenceService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      _db.collection('users').doc(uid).collection('presence').doc('primary');

  Future<void> setOnline(String uid) => _ref(uid).set({
    'online': true,
    'lastSeen': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  Future<void> setOffline(String uid) => _ref(uid).set({
    'online': false,
    'lastSeen': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  Stream<Map<String, dynamic>?> watch(String uid) =>
      _ref(uid).snapshots().map((d) => d.data());

  Stream<bool> watchOnline(String uid) =>
      watch(uid).map((data) => data?['online'] == true);
}

class AurenPresenceHeartbeat {
  final AurenPresenceService service;
  Timer? _timer;

  AurenPresenceHeartbeat(this.service);

  void start(String uid) {
    _timer?.cancel();
    service.setOnline(uid);
    _timer = Timer.periodic(const Duration(seconds: 45), (_) {
      service.setOnline(uid);
    });
  }

  Future<void> stop(String uid) async {
    _timer?.cancel();
    _timer = null;
    await service.setOffline(uid);
  }
}
