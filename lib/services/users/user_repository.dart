import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_profile.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  UserRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> _doc(String uid) => _firestore.collection('users').doc(uid);

  Future<AurenUserProfile> getOrCreate(String uid) async {
    final ref = _doc(uid);
    final snapshot = await ref.get();
    if (snapshot.exists && snapshot.data() != null) return AurenUserProfile.fromMap(uid, snapshot.data()!);
    final profile = AurenUserProfile(uid: uid, displayName: 'AUREN User', createdAt: DateTime.now());
    await ref.set({...profile.toMap(), 'displayNameLower': 'auren user'});
    return profile;
  }

  Future<void> updateDisplayName(String uid, String name) {
    final clean = name.trim();
    if (clean.isEmpty || clean.length > 80) throw ArgumentError('Display name must be 1–80 characters.');
    return _doc(uid).set(
      {'displayName': clean, 'displayNameLower': clean.toLowerCase()},
      SetOptions(merge: true),
    );
  }

  Stream<AurenUserProfile?> watch(String uid) =>
      _doc(uid).snapshots().map((d) => d.exists && d.data() != null ? AurenUserProfile.fromMap(uid, d.data()!) : null);
}