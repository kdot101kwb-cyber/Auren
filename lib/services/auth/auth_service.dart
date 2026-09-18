import 'package:firebase_auth/firebase_auth.dart';

abstract interface class AurenAuthService {
  Stream<String?> get authStateChanges;
  String? get currentUserId;
  Future<String> signInAnonymously();
  Future<void> signOut();
}

class FirebaseAurenAuthService implements AurenAuthService {
  final FirebaseAuth _auth;

  FirebaseAurenAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  @override
  Stream<String?> get authStateChanges => _auth.authStateChanges().map((user) => user?.uid);

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<String> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return credential.user!.uid;
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
