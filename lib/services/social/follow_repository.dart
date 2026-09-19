import 'package:cloud_firestore/cloud_firestore.dart';

class FollowRepository {
  final FirebaseFirestore _db;
  FollowRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _follows => _db.collection('follows');
  DocumentReference<Map<String, dynamic>> _ref(String follower, String following) => _follows.doc('\${follower}_\$following');
  Stream<bool> watchFollowing(String follower, String following) => _ref(follower, following).snapshots().map((d) => d.exists);
  Future<void> toggle(String follower, String following, bool isFollowing) async {
    if (follower.isEmpty || following.isEmpty || follower == following) throw ArgumentError('Invalid follow relationship.');
    final ref = _ref(follower, following);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (isFollowing) { if (snap.exists) tx.delete(ref); return; }
      if (snap.exists) return;
      tx.set(ref, {'followerId': follower, 'followingId': following, 'createdAt': FieldValue.serverTimestamp()});
    });
  }
  Stream<int> followersCount(String uid) => _follows.where('followingId', isEqualTo: uid).snapshots().map((s) => s.size);
  Stream<int> followingCount(String uid) => _follows.where('followerId', isEqualTo: uid).snapshots().map((s) => s.size);
}