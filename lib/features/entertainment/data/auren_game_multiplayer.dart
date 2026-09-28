import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AurenGameMultiplayer {
  AurenGameMultiplayer({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? _lobbyId;

  String? get lobbyId => _lobbyId;
  String get playerId => _auth.currentUser?.uid ?? 'guest';

  Future<void> _ensureSignedIn() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
  }

  Future<String> createLobby({required int gameIndex}) async {
    await _ensureSignedIn();
    final ref = _db.collection('auren_game_lobbies').doc();
    final now = FieldValue.serverTimestamp();
    await ref.set({
      'gameIndex': gameIndex,
      'status': 'waiting',
      'hostId': playerId,
      'players': [playerId],
      'createdAt': now,
      'updatedAt': now,
      'state': <String, dynamic>{},
    });
    _lobbyId = ref.id;
    return ref.id;
  }

  Future<bool> joinLobby({
    required String lobbyId,
    required int gameIndex,
  }) async {
    await _ensureSignedIn();
    final ref = _db.collection('auren_game_lobbies').doc(lobbyId);
    final snapshot = await ref.get();
    if (!snapshot.exists) return false;

    final data = snapshot.data() ?? <String, dynamic>{};
    if (data['gameIndex'] != gameIndex) return false;
    if (data['status'] == 'finished') return false;

    final players = List<String>.from(data['players'] ?? const <String>[]);
    if (!players.contains(playerId)) players.add(playerId);
    if (players.length > 2) return false;

    await ref.update({
      'players': players,
      'status': players.length == 2 ? 'playing' : 'waiting',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _lobbyId = lobbyId;
    return true;
  }

  Stream<Map<String, dynamic>?> watchLobby(String lobbyId) {
    return _db.collection('auren_game_lobbies').doc(lobbyId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return snapshot.data();
    });
  }

  Future<void> updateState(Map<String, dynamic> state) async {
    final id = _lobbyId;
    if (id == null) return;
    await _db.collection('auren_game_lobbies').doc(id).update({
      'state': state,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> finishLobby() async {
    final id = _lobbyId;
    if (id == null) return;
    await _db.collection('auren_game_lobbies').doc(id).update({
      'status': 'finished',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveLobby() async {
    final id = _lobbyId;
    if (id == null) return;
    final ref = _db.collection('auren_game_lobbies').doc(id);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      _lobbyId = null;
      return;
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    final players = List<String>.from(data['players'] ?? const <String>[]);
    players.remove(playerId);

    if (players.isEmpty) {
      await ref.delete();
    } else {
      await ref.update({
        'players': players,
        'status': 'waiting',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    _lobbyId = null;
  }

  void clearLobby() {
    _lobbyId = null;
  }
}
