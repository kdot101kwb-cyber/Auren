import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AurenGameMultiplayer {
  AurenGameMultiplayer({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
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
    final controller = StreamController<Map<String, dynamic>?>();
    Map<String, dynamic>? lobby;
    Map<String, dynamic>? privateData;

    void emit() {
      final base = lobby;
      if (base == null) {
        controller.add(null);
        return;
      }
      final merged = Map<String, dynamic>.from(base);
      final state = Map<String, dynamic>.from((base['state'] as Map?)?.cast<String, dynamic>() ?? const {});
      if (privateData != null) {
        final hand = List<String>.from(privateData!['hand'] ?? const <String>[]);
        if (state['dominoHandCounts'] is Map) {
          final counts = Map<String, dynamic>.from(state['dominoHandCounts'] as Map);
          final opponentCount = counts.entries
              .where((e) => e.key.toString() != playerId)
              .map((e) => (e.value as num?)?.toInt() ?? 0)
              .fold<int>(0, (a, b) => a + b);
          state['dominoHand'] = hand;
          state['dominoCpu'] = List<String>.filled(opponentCount, 'HIDDEN');
        } else if (state['unoHandCounts'] is Map) {
          final counts = Map<String, dynamic>.from(state['unoHandCounts'] as Map);
          final opponentCount = counts.entries
              .where((e) => e.key.toString() != playerId)
              .map((e) => (e.value as num?)?.toInt() ?? 0)
              .fold<int>(0, (a, b) => a + b);
          state['unoHand'] = hand;
          state['unoCpu'] = List<String>.filled(opponentCount, 'HIDDEN');
        }
      }
      merged['state'] = state;
      controller.add(merged);
    }

    final lobbySub = _db.collection('auren_game_lobbies').doc(lobbyId).snapshots().listen((snapshot) {
      lobby = snapshot.exists ? snapshot.data() : null;
      emit();
    }, onError: controller.addError);
    final privateSub = _db.collection('auren_game_lobbies').doc(lobbyId)
        .collection('private_players').doc(playerId).snapshots().listen((snapshot) {
      privateData = snapshot.exists ? snapshot.data() : null;
      emit();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await lobbySub.cancel();
      await privateSub.cancel();
    };
    return controller.stream;
  }

  Future<bool> initializeLudoMatch() async {
    final id = _lobbyId;
    if (id == null) return false;
    await _ensureSignedIn();
    try {
      final result = await _functions.httpsCallable('initializeAurenLudoMatch').call({
        'lobbyId': id,
      });
      return result.data is Map && result.data['accepted'] == true;
    } on FirebaseFunctionsException {
      return false;
    }
  }

  Future<bool> submitLudoAction({
    required Map<String, dynamic> action,
    required int expectedVersion,
    required String moveId,
  }) async {
    final id = _lobbyId;
    if (id == null) return false;
    await _ensureSignedIn();
    try {
      final result = await _functions.httpsCallable('submitAurenLudoAction').call({
        'lobbyId': id,
        'action': action,
        'expectedVersion': expectedVersion,
        'moveId': moveId,
      });
      return result.data is Map && result.data['accepted'] == true;
    } on FirebaseFunctionsException {
      return false;
    }
  }

  Future<bool> initializeDominoMatch() async {
    final id=_lobbyId; if(id==null)return false; await _ensureSignedIn();
    try { final r=await _functions.httpsCallable('initializeAurenDominoMatch').call({'lobbyId':id});
      return r.data is Map && r.data['accepted']==true;
    } on FirebaseFunctionsException { return false; }
  }

  Future<bool> submitDominoAction({required Map<String,dynamic> action,required int expectedVersion,required String moveId}) async {
    final id=_lobbyId; if(id==null)return false; await _ensureSignedIn();
    try { final r=await _functions.httpsCallable('submitAurenDominoAction').call({
      'lobbyId':id,'action':action,'expectedVersion':expectedVersion,'moveId':moveId});
      return r.data is Map && r.data['accepted']==true;
    } on FirebaseFunctionsException { return false; }
  }

  Future<bool> initializeUnoMatch() async {
    final id=_lobbyId; if(id==null)return false; await _ensureSignedIn();
    try { final r=await _functions.httpsCallable('initializeAurenUnoMatch').call({'lobbyId':id});
      return r.data is Map && r.data['accepted']==true;
    } on FirebaseFunctionsException { return false; }
  }

  Future<bool> submitUnoAction({required Map<String,dynamic> action,required int expectedVersion,required String moveId}) async {
    final id=_lobbyId; if(id==null)return false; await _ensureSignedIn();
    try { final r=await _functions.httpsCallable('submitAurenUnoAction').call({
      'lobbyId':id,'action':action,'expectedVersion':expectedVersion,'moveId':moveId});
      return r.data is Map && r.data['accepted']==true;
    } on FirebaseFunctionsException { return false; }
  }

  Future<bool> submitState({
    required Map<String, dynamic> state,
    required int expectedVersion,
    required String moveId,
  }) async {
    final id = _lobbyId;
    if (id == null) return false;
    await _ensureSignedIn();
    try {
      final result = await _functions.httpsCallable('submitAurenGameMove').call({
        'lobbyId': id,
        'gameIndex': state['gameIndex'] ?? 50,
        'state': state,
        'expectedVersion': expectedVersion,
        'moveId': moveId,
      });
      return result.data is Map && result.data['accepted'] == true;
    } on FirebaseFunctionsException {
      return false;
    }
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
