import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_profile.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<AurenUserProfile> getOrCreate(String uid) async {
    final ref = _doc(uid);
    final snapshot = await ref.get();

    if (snapshot.exists && snapshot.data() != null) {
      return AurenUserProfile.fromMap(uid, snapshot.data()!);
    }

    final profile = AurenUserProfile(
      uid: uid,
      displayName: 'AUREN User',
      createdAt: DateTime.now(),
    );

    await ref.set(profile.toMap());
    return profile;
  }
}
