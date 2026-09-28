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
      'guestId': null,
      'players': [playerId],
      'turnPlayerId': playerId,
      'stateVersion': 0,
      'lastMoveId': null,
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
    return _db.runTransaction<bool>((tx) async {
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) return false;
      final data = snapshot.data() ?? <String, dynamic>{};
      if (data['gameIndex'] != gameIndex || data['status'] == 'finished') return false;

      final hostId = data['hostId']?.toString();
      final guestId = data['guestId']?.toString();
      final players = List<String>.from(data['players'] ?? const <String>[]);

      if (players.contains(playerId)) {
        _lobbyId = lobbyId;
        return true;
      }
      if (hostId == null || guestId != null || players.length >= 2) return false;

      players.add(playerId);
      tx.update(ref, {
        'guestId': playerId,
        'players': players,
        'status': 'playing',
        'turnPlayerId': data['turnPlayerId']?.toString() ?? hostId,
        'stateVersion': (data['stateVersion'] as num?)?.toInt() ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _lobbyId = lobbyId;
      return true;
    });
  }

  Stream<Map<String, dynamic>?> watchLobby(String lobbyId) {
    return _db.collection('auren_game_lobbies').doc(lobbyId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return snapshot.data();
    });
  }

  Future<bool> submitState({
    required Map<String, dynamic> state,
    required int expectedVersion,
    required String moveId,
  }) async {
    final id = _lobbyId;
    if (id == null) return false;
    final ref = _db.collection('auren_game_lobbies').doc(id);
    return _db.runTransaction<bool>((tx) async {
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) return false;
      final data = snapshot.data() ?? <String, dynamic>{};
      final status = data['status']?.toString();
      final turn = data['turnPlayerId']?.toString();
      final version = (data['stateVersion'] as num?)?.toInt() ?? 0;
      if (status != 'playing' || turn != playerId || version != expectedVersion) return false;
      if (data['lastMoveId']?.toString() == moveId) return true;

      final players = List<String>.from(data['players'] ?? const <String>[]);
      final opponent = players.firstWhere(
        (id) => id != playerId,
        orElse: () => playerId,
      );
      final finished = state['matchFinished'] == true;
      tx.update(ref, {
        'state': state,
        'stateVersion': version + 1,
        'turnPlayerId': finished ? null : opponent,
        'lastMoveId': moveId,
        'updatedAt': FieldValue.serverTimestamp(),
        if (finished) 'status': 'finished',
      });
      return true;
    });
  }

  Future<void> seedState(Map<String, dynamic> state) async {
    final id = _lobbyId;
    if (id == null) return;
    final ref = _db.collection('auren_game_lobbies').doc(id);
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? <String, dynamic>{};
      final version = (data['stateVersion'] as num?)?.toInt() ?? 0;
      if (data['hostId']?.toString() != playerId || version != 0) return;
      final existing = data['state'];
      if (existing is Map && existing.isNotEmpty) return;
      tx.update(ref, {
        'state': state,
        'stateVersion': 0,
        'turnPlayerId': data['turnPlayerId']?.toString() ?? playerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> finishLobby() async {
    final id = _lobbyId;
    if (id == null) return;
    await _db.collection('auren_game_lobbies').doc(id).update({
      'status': 'finished',
      'turnPlayerId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveLobby() async {
    final id = _lobbyId;
    if (id == null) return;
    final ref = _db.collection('auren_game_lobbies').doc(id);
    try {
      await _db.runTransaction((tx) async {
        final snapshot = await tx.get(ref);
        if (!snapshot.exists) return;
        final data = snapshot.data() ?? <String, dynamic>{};
        final players = List<String>.from(data['players'] ?? const <String>[]);
        players.remove(playerId);
        if (players.isEmpty) {
          tx.delete(ref);
          return;
        }
        final hostId = data['hostId']?.toString();
        final nextHost = hostId == playerId ? players.first : hostId;
        tx.update(ref, {
          'players': players,
          'hostId': nextHost,
          'guestId': players.length > 1 ? players[1] : null,
          'status': players.length == 2 ? 'playing' : 'waiting',
          'turnPlayerId': players.length == 2
              ? (data['turnPlayerId']?.toString() == playerId ? players.first : data['turnPlayerId'])
              : players.first,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } finally {
      _lobbyId = null;
    }
  }

  void clearLobby() {
    _lobbyId = null;
  }
}
