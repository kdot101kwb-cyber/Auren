import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AurenCommunityMemoryService {
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  AurenCommunityMemoryService({FirebaseFirestore? db, FirebaseAuth? auth})
      : db = db ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;
  String get uid => auth.currentUser?.uid ?? (throw StateError('Sign in required'));
}
