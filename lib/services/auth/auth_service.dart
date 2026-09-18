abstract interface class AurenAuthService {
  Future<String?> currentUserId();
  Future<String> signInAnonymously();
  Future<void> signOut();
}

/// Firebase-ready contract. Replace the adapter internals when Firebase is configured.
class FirebaseAuthService implements AurenAuthService {
  String? _userId;

  @override
  Future<String?> currentUserId() async => _userId;

  @override
  Future<String> signInAnonymously() async {
    _userId ??= 'local-user';
    return _userId!;
  }

  @override
  Future<void> signOut() async => _userId = null;
}
