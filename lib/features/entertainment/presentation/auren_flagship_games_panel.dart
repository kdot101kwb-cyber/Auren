import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/auren_game_progress.dart';
import '../data/auren_game_multiplayer.dart';
import 'auren_global_gaming_leaderboard_screen.dart';
import 'auren_gaming_profile_screen.dart';
import 'auren_gaming_tournament_screen.dart';
import 'auren_live_spectator_screen.dart';

class AurenFlagshipGamesPanel extends StatefulWidget {
  final int gameIndex;
  final String? initialLobbyId;
  const AurenFlagshipGamesPanel({super.key, required this.gameIndex, this.initialLobbyId});
  @override State<AurenFlagshipGamesPanel> createState() => _AurenFlagshipGamesPanelState();
}

class _AurenFlagshipGamesPanelState extends State<AurenFlagshipGamesPanel> {
  int get _gameId => widget.gameIndex >= 50 ? widget.gameIndex : (widget.gameIndex >= 3 ? widget.gameIndex + 50 : widget.gameIndex);
  int get _localIndex => _gameId >= 53 ? _gameId - 50 : _gameId;
  final _rng = Random();
  final _multiplayer = AurenGameMultiplayer();
  StreamSubscription<Map<String, dynamic>?>? _lobbySubscription;
  Timer? _matchmakingTimer;
  bool _matchmaking = false;
  String? _lobbyId;
  String _onlineStatus = 'Offline';
  String? _turnPlayerId;
  int _stateVersion = 0;
  int _localMoveCounter = 0;
  int _score = 0, _round = 0, _hp = 100, _streak = 0, _energy = 100, _distance = 0;
  int _bestScore = 0, _wins = 0, _savedRounds = 0;
  int _serverRating = 1000, _serverMatches = 0, _serverLosses = 0, _serverDraws = 0;
  String? _matchWinnerId;
  String _matchResult = 'in_progress';
  bool _tournamentResultSent = false;
  bool _onlineInitializationRequested = false;
  String _message = 'ابدأ الجولة';

  final List<int> _ludo = [-1, -1, -1, -1];
  final List<int> _cpuLudo = [-1, -1, -1, -1];
  int _ludoDice = 0;
  int? _ludoPendingDice;
  static const _ludoSafe = {1, 9, 14, 22, 27, 35, 40, 48};
  static const _ludoStart = [1, 14, 27, 40];

  List<String> _dominoHand = [];
  List<String> _dominoCpu = [];
  List<String> _dominoPool = [];
  List<String> _dominoBoard = [];
  bool _dominoPlayerTurn = true;
  int _dominoLeft = 0, _dominoRight = 0;

  List<String> _unoHand = [];
  List<String> _unoCpu = [];
  List<String> _unoDeck = [];
  List<String> _unoDiscard = [];
  int _unoSelected = 0;
  String _unoColor = 'R';
  bool _unoPlayerTurn = true;
  int _unoPendingDraw = 0;
  bool _unoSkipNext = false;

  int _crimeCase = 1, _crimePhase = 0, _crimeEvidence = 0, _crimeScore = 0;
  final Set<String> _crimeCollected = {};
  String _crimeSuspect = '';

  static const _names = [
    '🎲 Ludo','🁫 Dominoes','🃏 UNO','🕵️ Crime Files',
    '⚽ AUREN Football Pro','🏀 Basketball Pro','🥊 Boxing Champion',
    '⚔️ Ancient & Modern Wars','🥷 Samurai Legacy','🏎️ AUREN Street Racing',
  ];

  @override
  void initState() {
    super.initState();
    _reset(initializing: true);
    _loadProgress();
    if (widget.initialLobbyId != null && widget.initialLobbyId!.isNotEmpty) {
      _watchLobby(widget.initialLobbyId!);
    }
  }

  Future<void> _loadProgress() async {
    final progress = await AurenGameProgress.load(_gameId);
    if (!mounted) return;
    setState(() {
      _bestScore = progress['best'] ?? 0;
      _wins = progress['wins'] ?? 0;
      _savedRounds = progress['round'] ?? 0;
    });
  }

  Future<void> _saveProgress({bool won = false}) async {
    final nextWins = _wins + (won ? 1 : 0);
    await AurenGameProgress.save(
      gameIndex: _gameId,
      score: _score,
      round: _round,
      wins: nextWins,
    );
    if (!mounted) return;
    setState(() {
      _wins = nextWins;
      if (_score > _bestScore) _bestScore = _score;
      _savedRounds = _round;
    });
  }

  @override
  void dispose() {
    _matchmakingTimer?.cancel();
    _lobbySubscription?.cancel();
    _multiplayer.leaveLobby();
    super.dispose();
  }

  bool get _onlineMatch => _lobbyId != null;
  bool get _isMyTurn => !_onlineMatch || _turnPlayerId == _multiplayer.playerId;
  String _nextMoveId() => '${_multiplayer.playerId}-${++_localMoveCounter}';

  Map<String, dynamic> _gameState() => {
    'gameIndex': _gameId,
    'score': _score, 'round': _round, 'hp': _hp, 'streak': _streak,
    'energy': _energy, 'distance': _distance, 'message': _message,
    'ludo': _ludo, 'cpuLudo': _cpuLudo, 'ludoDice': _ludoDice, 'ludoPendingDice': _ludoPendingDice,
    'dominoHand': _dominoHand, 'dominoCpu': _dominoCpu,
    'dominoPool': _dominoPool, 'dominoBoard': _dominoBoard,
    'dominoPlayerTurn': _dominoPlayerTurn, 'dominoLeft': _dominoLeft,
    'dominoRight': _dominoRight,
    'unoHand': _unoHand, 'unoCpu': _unoCpu, 'unoDeck': _unoDeck,
    'unoDiscard': _unoDiscard, 'unoColor': _unoColor,
    'unoPlayerTurn': _unoPlayerTurn, 'unoPendingDraw': _unoPendingDraw,
    'unoSkipNext': _unoSkipNext, 'unoSelected': _unoSelected,
    'crimeCase': _crimeCase, 'crimePhase': _crimePhase,
    'crimeEvidence': _crimeEvidence, 'crimeScore': _crimeScore,
    'crimeCollected': _crimeCollected.toList(), 'crimeSuspect': _crimeSuspect,
    'matchFinished': _lobbyId != null && (_hp <= 0 || _ludoWinner() != null),
  };

  void _applyGameState(Map<String, dynamic> state) {
    if (!mounted || state.isEmpty) return;
    setState(() {
      _score = (state['score'] as num?)?.toInt() ?? _score;
      _round = (state['round'] as num?)?.toInt() ?? _round;
      _hp = (state['hp'] as num?)?.toInt() ?? _hp;
      _streak = (state['streak'] as num?)?.toInt() ?? _streak;
      _energy = (state['energy'] as num?)?.toInt() ?? _energy;
      _distance = (state['distance'] as num?)?.toInt() ?? _distance;
      _message = state['message']?.toString() ?? _message;
      final l = state['ludo'];
      final cl = state['cpuLudo'];
      final hostId = state['ludoHostId']?.toString();
      final guestId = state['ludoGuestId']?.toString();
      final me = _multiplayer.playerId;
      final myPieces = me == hostId ? l : cl;
      final opponentPieces = me == hostId ? cl : l;
      if (myPieces is List) {
        for (var i = 0; i < min(4, myPieces.length); i++) {
          _ludo[i] = (myPieces[i] as num).toInt();
        }
      }
      if (opponentPieces is List) {
        for (var i = 0; i < min(4, opponentPieces.length); i++) {
          _cpuLudo[i] = (opponentPieces[i] as num).toInt();
        }
      }
      _ludoDice = (state['ludoDice'] as num?)?.toInt() ?? _ludoDice;
      _ludoPendingDice = (state['ludoPendingDice'] as num?)?.toInt();
      _dominoHand = List<String>.from(state['dominoHand'] ?? _dominoHand);
      _dominoCpu = List<String>.from(state['dominoCpu'] ?? _dominoCpu);
      _dominoPool = List<String>.from(state['dominoPool'] ?? _dominoPool);
      _dominoBoard = List<String>.from(state['dominoBoard'] ?? _dominoBoard);
      _dominoPlayerTurn = state['dominoPlayerTurn'] as bool? ?? _dominoPlayerTurn;
      _dominoLeft = (state['dominoLeft'] as num?)?.toInt() ?? _dominoLeft;
      _dominoRight = (state['dominoRight'] as num?)?.toInt() ?? _dominoRight;
      _unoHand = List<String>.from(state['unoHand'] ?? _unoHand);
      _unoCpu = List<String>.from(state['unoCpu'] ?? _unoCpu);
      _unoDeck = List<String>.from(state['unoDeck'] ?? _unoDeck);
      _unoDiscard = List<String>.from(state['unoDiscard'] ?? _unoDiscard);
      _unoColor = state['unoColor']?.toString() ?? _unoColor;
      _unoPlayerTurn = state['unoPlayerTurn'] as bool? ?? _unoPlayerTurn;
      _unoPendingDraw = (state['unoPendingDraw'] as num?)?.toInt() ?? _unoPendingDraw;
      _unoSkipNext = state['unoSkipNext'] as bool? ?? _unoSkipNext;
      _unoSelected = (state['unoSelected'] as num?)?.toInt() ?? _unoSelected;
      _crimeCase = (state['crimeCase'] as num?)?.toInt() ?? _crimeCase;
      _crimePhase = (state['crimePhase'] as num?)?.toInt() ?? _crimePhase;
      _crimeEvidence = (state['crimeEvidence'] as num?)?.toInt() ?? _crimeEvidence;
      _crimeScore = (state['crimeScore'] as num?)?.toInt() ?? _crimeScore;
      _crimeCollected
        ..clear()
        ..addAll(List<String>.from(state['crimeCollected'] ?? const <String>[]));
      _crimeSuspect = state['crimeSuspect']?.toString() ?? _crimeSuspect;
      final stats = state['playerStats'];
      if (stats is Map) { final mine = stats[_multiplayer.playerId]; if (mine is Map) { _score = (mine['score'] as num?)?.toInt() ?? _score; } }
      final result = state['matchResult'];
      if (result is Map) { _matchWinnerId = result['winnerId']?.toString(); _matchResult = result['result']?.toString() ?? _matchResult; }
    });
    if (_matchWinnerId != null && _matchResult != 'in_progress') { await _submitTournamentResultIfNeeded(); }
  }

  Future<void> _syncGameState() async {
    if (!_onlineMatch) return;
    final expectedVersion = _stateVersion;
    final moveId = _nextMoveId();
    try {
      final accepted = await _multiplayer.submitState(
        state: _gameState(),
        expectedVersion: expectedVersion,
        moveId: moveId,
      );
      if (!accepted) {
        if (mounted) setState(() => _message = '⚠️ الحركة لم تُقبل: دور الخصم أو حالة المباراة تغيّرت');
        return;
      }
      if (mounted) {
        setState(() {
          _stateVersion = expectedVersion + 1;
          _turnPlayerId = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _onlineStatus = 'Match sync unavailable');
    }
  }

  Future<void> _loadServerRanking() async {
    final data = await _multiplayer.getFlagshipRanking(gameIndex: _gameId);
    if (!mounted || data == null) return;
    setState(() { _wins = (data['wins'] as num?)?.toInt() ?? _wins; _serverLosses = (data['losses'] as num?)?.toInt() ?? _serverLosses; _serverDraws = (data['draws'] as num?)?.toInt() ?? _serverDraws; _serverMatches = (data['matches'] as num?)?.toInt() ?? _serverMatches; _serverRating = (data['rating'] as num?)?.toInt() ?? _serverRating; });
  }

  Future<void> _startMatchmaking() async {
    _matchmakingTimer?.cancel();
    setState(() => _matchmaking = true);
    final result = await _multiplayer.enqueueMatchmaking(gameIndex: _gameId);
    if (!mounted) return;
    if (result?['status'] == 'matched' && result?['matchId'] is String) {
      final id = result!['matchId'].toString();
      _watchLobby(id);
      await _initializeOnlineMatch();
      setState(() { _matchmaking = false; _onlineStatus = 'Matched • ' + id.substring(0, min(6, id.length)).toUpperCase(); });
      return;
    }
    setState(() => _onlineStatus = 'Searching for opponent…');
    _matchmakingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final status = await _multiplayer.getMatchmakingStatus();
      if (!mounted || status == null) return;
      if (status['status'] == 'matched' && status['matchId'] is String) {
        _matchmakingTimer?.cancel();
        final id = status['matchId'].toString();
        _watchLobby(id);
        await _initializeOnlineMatch();
        if (mounted) setState(() { _matchmaking = false; _onlineStatus = 'Matched • ' + id.substring(0, min(6, id.length)).toUpperCase(); });
      }
    });
  }

  Future<void> _cancelMatchmaking() async {
    _matchmakingTimer?.cancel();
    await _multiplayer.cancelMatchmaking();
    if (mounted) setState(() { _matchmaking = false; _onlineStatus = 'Offline'; });
  }

  Future<void> _initializeOnlineMatch() async {
    if (_onlineInitializationRequested) return;
    _onlineInitializationRequested = true;
    try {
    bool accepted = false;
    if (_localIndex == 0) {
      accepted = await _multiplayer.initializeLudoMatch();
    } else if (_localIndex == 1) {
      accepted = await _multiplayer.initializeDominoMatch();
    } else if (_localIndex == 2) {
      accepted = await _multiplayer.initializeUnoMatch();
    } else if (_gameId >= 53 && _gameId <= 59) {
      accepted = await _multiplayer.initializeFlagshipMatch();
    }
    if (!accepted) _onlineInitializationRequested = false;
    } catch (_) {
      _onlineInitializationRequested = false;
      rethrow;
    }
  }

  Future<void> _createLobby() async {
    try {
      final id = await _multiplayer.createLobby(gameIndex: _gameId);
      _watchLobby(id);
      if (widget.gameIndex == 1) {
        // Initialization is completed by the second player after the lobby becomes playable.
      }
      if (!mounted) return;
      setState(() => _onlineStatus = 'Waiting • ' + id.substring(0, min(6, id.length)).toUpperCase());
    } catch (_) {
      if (mounted) setState(() => _onlineStatus = 'Online unavailable');
    }
  }

  Future<void> _joinLobby() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join AUREN Match'),
        content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(hintText: 'Lobby ID')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Join'))],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty) return;
    try {
      final ok = await _multiplayer.joinLobby(lobbyId: code, gameIndex: _gameId);
      if (!ok) {
        if (mounted) setState(() => _onlineStatus = 'Lobby not available');
        return;
      }
      _watchLobby(code);
      if (widget.gameIndex == 0) {
        await _multiplayer.initializeLudoMatch();
      } else if (widget.gameIndex == 1) {
        await _multiplayer.initializeDominoMatch();
      } else if (widget.gameIndex == 2) {
        await _multiplayer.initializeUnoMatch();
      } else if (_localIndex >= 3 && _localIndex <= 9) {
        await _multiplayer.initializeFlagshipMatch();
      }
      if (mounted) setState(() => _onlineStatus = 'Connected • ' + code.substring(0, min(6, code.length)).toUpperCase());
    } catch (_) {
      if (mounted) setState(() => _onlineStatus = 'Online unavailable');
    }
  }

  void _watchLobby(String id) {
    _lobbySubscription?.cancel();
    _lobbyId = id;
    _turnPlayerId = null;
    _stateVersion = 0;
    _onlineInitializationRequested = false;
    _lobbySubscription = _multiplayer.watchLobby(id).listen((data) {
      if (!mounted || data == null) return;
      final players = List<String>.from(data['players'] ?? const <String>[]);
      final remoteVersion = (data['stateVersion'] as num?)?.toInt() ?? 0;
      final remoteTurn = data['turnPlayerId']?.toString();
      final remoteState = data['state'];
      if (remoteState is Map<String, dynamic> && remoteState.isNotEmpty && remoteVersion >= _stateVersion) {
        _stateVersion = remoteVersion;
        _applyGameState(remoteState);
      } else if (remoteVersion > _stateVersion) {
        _stateVersion = remoteVersion;
      }
      _turnPlayerId = remoteTurn;
      final matchResult = data['matchResult'];
      if (matchResult is Map) { _matchWinnerId = matchResult['winnerId']?.toString(); _matchResult = matchResult['result']?.toString() ?? _matchResult; }
      final status = data['status']?.toString() ?? 'waiting';
      if (status == 'playing' && !_onlineInitializationRequested && (remoteState is! Map || remoteState.isEmpty)) {
        unawaited(_initializeOnlineMatch());
      }
      final turnText = status == 'playing' ? (_isMyTurn ? 'Your turn' : 'Opponent turn') : 'Waiting';
      setState(() => _onlineStatus = status == 'playing' ? '2 Players • ' + turnText : turnText + ' • ' + players.length.toString() + '/2');
      if (status == 'finished') unawaited(_loadServerRanking());
    });
  }

  Future<void> _showLiveSpectator() async {
    final data = await _multiplayer.getLiveSpectatorMatches();
    if (!mounted) return;
    final matches = List<Map<String, dynamic>>.from(
      (data?['matches'] as List? ?? const []).map((x) => Map<String, dynamic>.from(x)),
    );
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: matches.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد مباريات مباشرة الآن. حاول لاحقاً.')))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final m = matches[i];
                    final players = List<String>.from(m['players'] ?? const <String>[]);
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.live_tv)),
                      title: Text('🎮 ' + _gameNameForId((m['gameIndex'] as num?)?.toInt() ?? 53)),
                      subtitle: Text('👥 ' + players.length.toString() + '/2 • Version ' + (m['stateVersion'] ?? 0).toString()),
                      trailing: const Text('LIVE', style: TextStyle(fontWeight: FontWeight.w900)),
                      onTap: () { Navigator.of(context).pop(); Navigator.of(this.context).push(MaterialPageRoute(builder: (_) => AurenLiveSpectatorScreen(lobbyId: m['lobbyId'].toString(), gameIndex: (m['gameIndex'] as num?)?.toInt() ?? 53))); },
                    );
                  },
                ),
        ),
      ),
    );
  }

  String _gameNameForId(int id) {
    const names = <int, String>{53: 'Crime Files', 54: 'Football Pro', 55: 'Basketball Pro', 56: 'Boxing Champion', 57: 'Ancient & Modern Wars', 58: 'Samurai Legacy', 59: 'Street Racing'};
    return names[id] ?? 'AUREN Game';
  }
  Future<void> _leaveLobby() async {
    await _lobbySubscription?.cancel();
    _lobbySubscription = null;
    await _multiplayer.leaveLobby();
    if (mounted) setState(() { _lobbyId = null; _turnPlayerId = null; _stateVersion = 0; _onlineStatus = 'Offline'; });
  }

  @override
  void didUpdateWidget(covariant AurenFlagshipGamesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameIndex != widget.gameIndex || oldWidget.initialLobbyId != widget.initialLobbyId) {
      unawaited(_leaveLobby());
      _reset();
      _onlineInitializationRequested = false;
      if (widget.initialLobbyId != null && widget.initialLobbyId!.isNotEmpty) _watchLobby(widget.initialLobbyId!);
      unawaited(_loadProgress());
    }
  }

  void _reset({bool initializing = false}) {
    void resetState() {
      _score = 0; _round = 0; _hp = 100; _streak = 0; _energy = 100; _distance = 0;
      _message = 'ابدأ الجولة';
      for (var i = 0; i < 4; i++) { _ludo[i] = -1; _cpuLudo[i] = -1; }
      _ludoDice = 0; _ludoPendingDice = null;
      _initDomino();
      _initUno();
      _crimeCase = 1; _crimePhase = 0; _crimeEvidence = 0; _crimeScore = 0;
      _crimeCollected.clear(); _crimeSuspect = '';
    }
    if (initializing) {
      resetState();
      return;
    }
    setState(() {
      resetState();
    });
  }

  Future<void> _submitTournamentResultIfNeeded() async {
    if (_tournamentResultSent || _lobbyId == null || _matchWinnerId == null || _matchResult == 'in_progress') return;
    final tournament = await _multiplayer.getTournament(gameIndex: _gameId);
    final matches = tournament?['matches'];
    if (matches is! List) return;
    final me = _multiplayer.playerId;
    Map<String,dynamic>? target;
    for (final raw in matches) {
      if (raw is! Map) continue;
      final m = Map<String,dynamic>.from(raw);
      if (m['status'] == 'pending' && (m['p1'] == me || m['p2'] == me)) { target = m; break; }
    }
    if (target == null) return;
    final id = target['id']?.toString();
    if (id == null) return;
    final result = await _multiplayer.submitTournamentMatchResult(
      gameIndex: _gameId, matchId: id, winnerId: _matchWinnerId!);
    if (result != null) {
      _tournamentResultSent = true;
      if (mounted) setState(() => _message = '🏆 تم تسجيل نتيجة البطولة والتأهل تلقائياً');
    }
  }

  Future<void> _submitFlagshipAction(String type, Map<String, dynamic> payload) async {
    if (!_onlineMatch || !_isMyTurn) return;
    final expectedVersion = _stateVersion;
    final accepted = await _multiplayer.submitFlagshipAction(
      action: {'type': type, 'payload': payload},
      expectedVersion: expectedVersion,
      moveId: _nextMoveId(),
    );
    if (!accepted && mounted) {
      setState(() => _message = '⚠️ الحركة رفضها الخادم — حدّث المباراة وحاول مرة أخرى');
    }
  }

  void _act() {
    if (!_isMyTurn) { setState(() => _message = '⏳ انتظر دورك'); return; }
    switch (_localIndex) {
      case 0:
        _ludoRoll();
        return;
      case 1:
        if (_onlineMatch) {
          _dominoOnlineDrawOrPlay();
          return;
        }
        _dominoDrawOrPlay();
        break;
      case 2: _unoDraw(); break;
      case 3: if (_onlineMatch) { _submitFlagshipAction('advance_case', {}); return; } _crimeAdvance(); break;
      case 4: if (_onlineMatch) { _submitFlagshipAction('shoot', {'lane': 1}); return; } _footballTurn(); break;
      case 5: if (_onlineMatch) { _submitFlagshipAction('shot', {'shot': 0}); return; } _basketballTurn(); break;
      case 6: if (_onlineMatch) { _submitFlagshipAction('boxing', {'move': 0}); return; } _boxingTurn(); break;
      case 7: if (_onlineMatch) { _submitFlagshipAction('mission', {'mission': 0}); return; } _warTurn(); break;
      case 8: if (_onlineMatch) { _submitFlagshipAction('samurai', {'move': 0}); return; } _samuraiTurn(); break;
      case 9: if (_onlineMatch) { _submitFlagshipAction('steer', {'lane': 1}); return; } _racingTurn(); break;
    }
    _saveProgress();
    _syncGameState();
  }

  void _ludoRoll() {
    if (!_isMyTurn || _ludoPendingDice != null || _ludoWinner() != null) return;
    if (_onlineMatch) {
      final expectedVersion = _stateVersion;
      _multiplayer.submitLudoAction(
        action: {'type': 'roll'},
        expectedVersion: expectedVersion,
        moveId: _nextMoveId(),
      ).then((accepted) {
        if (!accepted && mounted) {
          setState(() => _message = '⚠️ رمية Ludo رفضها الخادم — حدّث المباراة وحاول مرة أخرى');
        }
      });
      return;
    }
    _ludoDice = 1 + _rng.nextInt(6);
    _ludoPendingDice = _ludoDice;
    _message = '🎲 رميت ' + _ludoDice.toString() + ' • اختر قطعة قانونية';
    setState(() {});
  }

  bool _ludoCanMove(int i, int dice) {
    final p = _ludo[i];
    if (p == 56) return false;
    if (p == -1) return dice == 6;
    return p + dice <= 56;
  }

  void _ludoMove(int i) {
    if (!_isMyTurn) return;
    if (_onlineMatch) {
      if (_ludoPendingDice == null) return;
      final expectedVersion = _stateVersion;
      _multiplayer.submitLudoAction(
        action: {'type': 'move', 'pieceIndex': i},
        expectedVersion: expectedVersion,
        moveId: _nextMoveId(),
      ).then((accepted) {
        if (!accepted && mounted) {
          setState(() => _message = '⚠️ الحركة رفضها الخادم — قد تكون غير قانونية أو انتهى الدور');
        }
      });
      return;
    }
    final dice = _ludoPendingDice;
    if (dice == null || !_ludoCanMove(i, dice)) {
      _message = dice == null ? '🎲 ارمِ النرد أولاً' : '🚫 هذه القطعة لا يمكنها التحرك';
      setState(() {});
      return;
    }
    final next = _ludo[i] == -1 ? 1 : _ludo[i] + dice;
    _ludo[i] = next;
    _score += dice * 5;
    _round++;
    var captured = false;
    for (var j = 0; j < 4; j++) {
      if (_cpuLudo[j] >= 0 && _cpuLudo[j] < 56 &&
          _ludoGlobalCell(next, 0) == _ludoGlobalCell(_cpuLudo[j], 1) &&
          !_ludoSafe.contains(next)) {
        _cpuLudo[j] = -1;
        captured = true;
      }
    }
    _message = '🔵 القطعة ' + (i + 1).toString() + ' إلى ' + next.toString() + '/56' +
        (captured ? ' • 💥 أعدت قطعة الخصم للبداية' : '');
    if (next == 56) _message += ' • 🏠 وصلت للبيت!';
    _ludoPendingDice = null;
    if (_ludoWinner() == 'player') {
      _score += 250;
      _message = '🏆 فوز Ludo! كل قطعك وصلت للبيت';
      _saveProgress(won: true);
    } else {
      _cpuLudoTurn();
    }
    setState(() {});
  }

  int _ludoGlobalCell(int pos, int player) {
    if (pos <= 0 || pos >= 56) return -1;
    return (pos + _ludoStart[player]) % 52;
  }

  void _cpuLudoTurn() {
    if (_ludoWinner() != null) return;
    final dice = 1 + _rng.nextInt(6);
    final legal = List.generate(4, (i) => i).where((i) {
      final p = _cpuLudo[i];
      return p < 56 && ((p == -1 && dice == 6) || (p >= 0 && p + dice <= 56));
    }).toList();
    if (legal.isNotEmpty) {
      legal.sort((a, b) => _cpuLudo[b].compareTo(_cpuLudo[a]));
      final i = legal.first;
      _cpuLudo[i] = _cpuLudo[i] == -1 ? 1 : _cpuLudo[i] + dice;
      _message += ' • 🤖 الخصم تحرك';
    } else {
      _message += ' • 🤖 الخصم لم يجد حركة';
    }
    if (_ludoWinner() == 'cpu') _message = '🤖 الخصم أكمل قطعه أولاً';
  }

  String? _ludoWinner() {
    if (_ludo.every((p) => p == 56)) return 'player';
    if (_cpuLudo.every((p) => p == 56)) return 'cpu';
    return null;
  }

  void _initDomino() {
    _dominoPool = [
      for (var a = 0; a <= 6; a++)
        for (var b = a; b <= 6; b++) a.toString() + '|' + b.toString()
    ]..shuffle(_rng);
    _dominoHand = List<String>.from(_dominoPool.take(7));
    _dominoPool = _dominoPool.skip(7).toList();
    _dominoCpu = List<String>.from(_dominoPool.take(7));
    _dominoPool = _dominoPool.skip(7).toList();
    final first = _dominoPool.removeLast();
    _dominoBoard = [first];
    final p = _dominoValues(first);
    _dominoLeft = p[0]; _dominoRight = p[1];
    _dominoPlayerTurn = true;
  }

  List<int> _dominoValues(String piece) => piece.split('|').map(int.parse).toList();

  bool _dominoLegal(String piece) {
    final p = _dominoValues(piece);
    return p[0] == _dominoLeft || p[1] == _dominoLeft ||
        p[0] == _dominoRight || p[1] == _dominoRight;
  }

  void _dominoPlayOnline(int index) {
    if (!_isMyTurn || index < 0 || index >= _dominoHand.length) return;
    if (!_dominoLegal(_dominoHand[index])) {
      setState(() => _message = '🚫 هذه القطعة لا تطابق أي طرف');
      return;
    }
    _multiplayer.submitDominoAction(
      action: {'type':'play','pieceIndex':index},
      expectedVersion:_stateVersion, moveId:_nextMoveId(),
    );
  }

  void _dominoPlay(int index) {
    if (_onlineMatch) { _dominoPlayOnline(index); return; }
    if (!_isMyTurn || !_dominoPlayerTurn || index < 0 || index >= _dominoHand.length) return;
    final piece = _dominoHand[index];
    if (!_dominoLegal(piece)) {
      _message = '🚫 ' + piece + ' لا يطابق أي طرف';
      setState(() {});
      return;
    }
    _dominoPlace(piece);
    _dominoHand.removeAt(index);
    _score += 20; _streak++; _round++;
    if (_dominoHand.isEmpty) {
      _score += 200; _message = '🏆 فوز Dominoes! انتهت يدك';
      _saveProgress(won: true);
      setState(() {});
      return;
    }
    _dominoPlayerTurn = false;
    _dominoCpuMove();
    setState(() {});
    _syncGameState();
  }

  void _dominoPlace(String piece) {
    final p = _dominoValues(piece);
    if (p[1] == _dominoLeft) {
      _dominoLeft = p[0]; _dominoBoard.insert(0, piece);
    } else if (p[0] == _dominoLeft) {
      _dominoLeft = p[1]; _dominoBoard.insert(0, piece);
    } else if (p[0] == _dominoRight) {
      _dominoRight = p[1]; _dominoBoard.add(piece);
    } else {
      _dominoRight = p[0]; _dominoBoard.add(piece);
    }
  }

  void _dominoCpuMove() {
    final legal = _dominoCpu.where(_dominoLegal).toList();
    if (legal.isNotEmpty) {
      final piece = legal[_rng.nextInt(legal.length)];
      _dominoPlace(piece); _dominoCpu.remove(piece);
      _message = '🁫 الخصم لعب ' + piece + ' • دورك';
    } else if (_dominoPool.isNotEmpty) {
      _dominoCpu.add(_dominoPool.removeLast());
      _message = '🤖 الخصم سحب قطعة • دورك';
    } else {
      _message = '⏭️ الخصم مرّر • دورك';
    }
    if (_dominoCpu.isEmpty) _message = '🤖 الخصم أنهى يده — الجولة للخصم';
    _dominoPlayerTurn = true;
  }

  void _dominoOnlineDrawOrPlay() {
    if (!_isMyTurn || !_dominoPlayerTurn) return;
    final expectedVersion = _stateVersion;
    if (_dominoHand.any(_dominoLegal)) {
      setState(() => _message = '🁫 لديك قطعة قانونية — اخترها من يدك');
      return;
    }
    _multiplayer.submitDominoAction(
      action: {'type': 'draw'}, expectedVersion: expectedVersion, moveId: _nextMoveId(),
    );
  }

  void _dominoDrawOrPlay() {
    if (!_isMyTurn || !_dominoPlayerTurn) return;
    if (_dominoHand.any(_dominoLegal)) {
      _message = '🁫 لديك قطعة قانونية — اخترها من يدك';
    } else if (_dominoPool.isNotEmpty) {
      final piece = _dominoPool.removeLast();
      _dominoHand.add(piece); _message = '🁫 سحبت ' + piece;
    } else {
      _dominoPlayerTurn = false; _dominoCpuMove();
    }
    setState(() {});
  }

  void _initUno() {
    _unoDeck = [
      for (final c in ['R','B','G','Y']) for (var n=0;n<=9;n++) c+n.toString(),
      for (final c in ['R','B','G','Y']) ...[c+'+2',c+'+2',c+'S',c+'S',c+'R',c+'R']
    ]..shuffle(_rng);
    _unoDeck.addAll(['W','W','W+4','W+4']);
    _unoHand=List<String>.from(_unoDeck.take(7)); _unoDeck=_unoDeck.skip(7).toList();
    _unoCpu=List<String>.from(_unoDeck.take(7)); _unoDeck=_unoDeck.skip(7).toList();
    _unoDiscard=[_unoDeck.removeLast()];
    _unoColor=_unoColorOf(_unoDiscard.last)=='W'?['R','B','G','Y'][_rng.nextInt(4)]:_unoColorOf(_unoDiscard.last);
    _unoSelected=0; _unoPlayerTurn=true; _unoPendingDraw=0; _unoSkipNext=false;
  }

  String _unoColorOf(String card)=>card.startsWith('W')?'W':card[0];
  String _unoRankOf(String card)=>card.startsWith('W')?card:card.substring(1);
  bool _unoPlayable(String card)=>_unoColorOf(card)==_unoColor||_unoRankOf(card)==_unoRankOf(_unoDiscard.last)||card.startsWith('W');

  void _unoPlay(int index) {
    if (_onlineMatch) { _unoPlayOnline(index); return; }
    if (!_isMyTurn || !_unoPlayerTurn || index<0 || index>=_unoHand.length) return;
    final card=_unoHand[index];
    if (!_unoPlayable(card)) { _message='🚫 '+card+' غير صالح على اللون '+_unoColor; setState((){}); return; }
    _unoHand.removeAt(index); _unoDiscard.add(card);
    _unoColor=card.startsWith('W')?['R','B','G','Y'][_rng.nextInt(4)]:card[0];
    final rank=_unoRankOf(card); _score+=25; _round++; _streak++;
    if (_unoHand.isEmpty) { _score+=300; _message='🏆 فوز UNO! تخلّصت من كل بطاقاتك'; _saveProgress(won:true); setState((){}); return; }
    if(rank=='+2')_unoPendingDraw=2; if(rank=='S'||rank=='R')_unoSkipNext=true;
    _message='🃏 لعبت '+card+' • اللون الحالي '+_unoColor; _unoPlayerTurn=false; _unoCpuMove(); setState((){});
  }

  void _unoPlayOnline(int index) {
    if (!_isMyTurn || index<0 || index>=_unoHand.length) return;
    final card=_unoHand[index];
    if (!_unoPlayable(card)) { setState(()=>_message='🚫 '+card+' غير صالح'); return; }
    _multiplayer.submitUnoAction(action:{'type':'play','card':card},expectedVersion:_stateVersion,moveId:_nextMoveId());
  }

  void _unoDraw() {
    if (_onlineMatch) { _unoDrawOnline(); return; }
    if (!_isMyTurn || !_unoPlayerTurn) return;
    if (_unoPendingDraw>0) { for(var i=0;i<_unoPendingDraw;i++)_unoDrawOne(_unoHand); _unoPendingDraw=0; _message='🃏 سحبت عقوبة — دور الخصم'; _unoPlayerTurn=false; _unoCpuMove(); }
    else { _unoDrawOne(_unoHand); _message='🃏 سحبت بطاقة'; }
    setState((){}); _syncGameState();
  }

  void _unoDrawOnline() {
    if (!_isMyTurn) return;
    _multiplayer.submitUnoAction(action:{'type':'draw'},expectedVersion:_stateVersion,moveId:_nextMoveId());
  }

  void _unoDrawOne(List<String> hand){if(_unoDeck.isEmpty)_unoRecycle();if(_unoDeck.isNotEmpty)hand.add(_unoDeck.removeLast());}
  void _unoRecycle(){if(_unoDiscard.length<=1)return;final keep=_unoDiscard.removeLast();_unoDeck=List<String>.from(_unoDiscard)..shuffle(_rng);_unoDiscard=[keep];}
  void _unoCpuMove(){if(_unoCpu.isEmpty)return;if(_unoPendingDraw>0){for(var i=0;i<_unoPendingDraw;i++)_unoDrawOne(_unoCpu);_unoPendingDraw=0;_unoPlayerTurn=true;_message='🤖 الخصم سحب العقوبة • دورك';return;}if(_unoSkipNext){_unoSkipNext=false;_unoPlayerTurn=true;_message='⏭️ تخطّي الخصم • دورك';return;}final legal=_unoCpu.where(_unoPlayable).toList();if(legal.isEmpty){_unoDrawOne(_unoCpu);_message='🤖 الخصم سحب بطاقة • دورك';}else{final card=legal[_rng.nextInt(legal.length)];_unoCpu.remove(card);_unoDiscard.add(card);_unoColor=card.startsWith('W')?['R','B','G','Y'][_rng.nextInt(4)]:card[0];final rank=_unoRankOf(card);if(rank=='+2')_unoPendingDraw=2;if(rank=='S'||rank=='R')_unoSkipNext=true;_message='🤖 الخصم لعب '+card+' • دورك';}if(_unoCpu.isEmpty){_message='🤖 الخصم فاز بالجولة';_hp=max(1,_hp-20);}_unoPlayerTurn=true;}

  void _crimeAdvance() {
    if (!_isMyTurn) return;
    const clues = [
      'بصمة على مقبض الباب','كاميرا توقفت عند 03:12','إيصال من متجر قريب',
      'رسالة مشفرة في الهاتف','رقم لوحة ظهر في الشارع','بصمة رقمية تربط الحساب بالموقع',
    ];
    const suspects = ['آدم','ليان','سامي'];
    if (_crimePhase == 0) {
      _crimePhase = 1; _message = '🕵️ وصلت لمسرح الجريمة — ابحث عن الأدلة';
    } else if (_crimePhase == 1) {
      final available = clues.where((c) => !_crimeCollected.contains(c)).toList();
      if (available.isNotEmpty) {
        final clue = available[_rng.nextInt(available.length)];
        _crimeCollected.add(clue); _crimeEvidence++; _crimeScore += 15; _score += 18;
        _message = '🔎 دليل: ' + clue;
        if (_crimeEvidence >= 5) { _crimePhase = 2; _message += ' • الأدلة الأساسية اكتملت'; }
      }
    } else if (_crimePhase == 2) {
      _crimePhase = 3; _crimeSuspect = suspects[_rng.nextInt(suspects.length)];
      _message = '🧠 التحليل يقترح مشتبهًا: ' + _crimeSuspect + ' • راجع الأدلة';
    } else if (_crimePhase == 3) {
      final correct = _crimeSuspect == 'سامي';
      if (correct) { _crimeScore += 150; _score += 200; _crimePhase = 4; _message = '🏆 أغلقت القضية بنجاح'; _saveProgress(won: true); }
      else { _hp = max(1, _hp - 15); _crimePhase = 4; _message = '⚠️ الاتهام لم يتطابق مع الأدلة'; }
    } else {
      _crimeCase++; _crimePhase = 0; _crimeEvidence = 0; _crimeScore = 0; _crimeCollected.clear(); _crimeSuspect = '';
      _message = '📁 بدأت قضية جديدة رقم ' + _crimeCase.toString();
    }
    _saveProgress();
    _syncGameState();
    setState(() {});
  }

  void _footballTurn() { final goal = _rng.nextInt(100) > 48; _round++; _score += goal ? 30 : 5; _message = goal ? '⚽ GOAL! هجمة ناجحة' : '🧤 تصدّي!'; }
  void _basketballTurn() { final shot = _rng.nextDouble(), points = shot > .78 ? 3 : shot > .38 ? 2 : 0; _round++; _score += points * 10; _message = points > 0 ? '🏀 ' + points.toString() + ' نقاط!' : '🏀 ضاعت الرمية'; }
  void _boxingTurn() { if (_energy < 15) { _message = '🥊 طاقتك منخفضة — استخدم المراوغة'; return; } _energy = max(0, _energy - 15); _round++; if (_rng.nextInt(100) > 42) { final damage = 8 + _rng.nextInt(13); _score += damage * 2; _streak++; _message = '🥊 لكمة ناجحة • ضرر ' + damage.toString(); } else { final damage = 5 + _rng.nextInt(11); _hp = max(0, _hp - damage); _streak = 0; _message = '🥊 الخصم ردّ • -' + damage.toString() + ' HP'; } }
  void _warTurn() { const m = ['أمّن نقطة الإمداد','احمِ القافلة','استعد الموقع','أنقذ الفريق','أكمل الانسحاب الآمن']; _round++; _score += 22; _streak++; _message = '⚔️ المهمة ' + (((_round - 1) % m.length) + 1).toString() + ': ' + m[(_round - 1) % m.length]; }
  void _samuraiTurn() { const m = ['سحب السيف','صدّ الضربة','خطوة جانبية','ضربة دقيقة']; final ok = _rng.nextDouble() > .25; _round++; if (ok) { _score += 25; _streak++; _message = '🥷 ' + m[_rng.nextInt(m.length)] + ' • ناجحة'; } else { _hp = max(0, _hp - 8); _streak = 0; _message = '🥷 تم صدّ الهجمة • -8 HP'; } }
  void _racingTurn() { final speed = 60 + _rng.nextInt(41), drift = _rng.nextDouble() > .35; _distance += speed ~/ 4; _energy = max(0, _energy - (drift ? 8 : 4)); _round++; _score += drift ? 25 : 10; _streak = drift ? _streak + 1 : 0; _message = '🏎️ سرعة ' + speed.toString() + ' km/h • ' + (drift ? 'انجراف مضبوط' : 'حافظ على المسار'); }

  String get _button => ['ارمِ النرد','اسحب قطعة','اسحب بطاقة','تقدم في القضية','سدّد','ارمِ الكرة','هاجم','نفّذ المهمة','نفّذ الحركة','سباق!'][_localIndex];

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(_names[_localIndex], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Align(alignment: AlignmentDirectional.centerStart, child: OutlinedButton.icon(onPressed: _showLiveSpectator, icon: const Icon(Icons.live_tv), label: const Text('🔴 Live Matches'))),
      const SizedBox(width: 8),
      OutlinedButton.icon(onPressed: () { Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AurenGamingProfileScreen())); }, icon: const Icon(Icons.person), label: const Text('Gaming Profile')),
      const SizedBox(height: 6), Text('جولة ' + _round.toString() + ' • ⭐ ' + _score.toString() + ' • 🔥 Combo ' + _streak.toString()),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('🌐 ' + _onlineStatus, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (_lobbyId != null) IconButton(onPressed: _leaveLobby, icon: const Icon(Icons.close)),
        ]),
        if (_lobbyId == null && !_matchmaking) Row(children: [
          Expanded(child: FilledButton.icon(onPressed: _startMatchmaking, icon: const Icon(Icons.sports_esports), label: const Text('Find Opponent'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: _createLobby, child: const Text('Create Match'))),
        ]),
        if (_lobbyId == null && !_matchmaking) const SizedBox(height: 8),
        if (_lobbyId == null && !_matchmaking) OutlinedButton(onPressed: _joinLobby, child: const Text('Join Match')),
        if (_lobbyId == null && !_matchmaking) OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AurenGamingTournamentScreen(initialGameIndex: _gameId))), icon: const Icon(Icons.emoji_events), label: const Text('Tournament')),
        if (_lobbyId == null && _matchmaking) FilledButton.tonal(onPressed: _cancelMatchmaking, child: const Text('Cancel Search')),
        const SizedBox(height: 8),
        Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Best', _bestScore.toString()),
          _stat('Wins', _wins.toString()),
          _stat('Rating', _serverRating.toString()),
          _stat('Matches', _serverMatches.toString()),
        ]),
      ]))),
      const SizedBox(height: 12),
      if (_localIndex == 0) _ludoBoard(),
      if (_localIndex == 1) _dominoBoard(),
      if (_localIndex == 2) _unoBoard(),
      if (_localIndex == 3) _crimeBoard(),
      if (_localIndex >= 4) _actionBoard(),
      if (_localIndex >= 4) _controls(),
      const SizedBox(height: 12),
      if (_onlineMatch && _matchResult != 'in_progress') Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(_matchResult == 'draw' ? '🤝 تعادل • النتيجة محفوظة من الخادم' : (_matchWinnerId == _multiplayer.playerId ? '🏆 فوز مسجل من الخادم' : '📊 انتهت المباراة'), style: const TextStyle(fontWeight: FontWeight.w900)))),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(_message, style: const TextStyle(fontWeight: FontWeight.w800)))),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _hp > 0 ? _act : _reset, icon: Icon(_hp > 0 ? Icons.play_arrow : Icons.refresh), label: Text(_hp > 0 ? _button : 'إعادة المباراة')),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh), label: const Text('لعبة جديدة')),
    ]);
  }

  Widget _stat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 11)),
  ]);

  Widget _ludoBoard() => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('النرد: ' + (_ludoDice == 0 ? '—' : _ludoDice.toString())),
    const SizedBox(height: 8),
    Wrap(spacing: 6, runSpacing: 6, children: List.generate(4, (i) => FilledButton.tonal(
      onPressed: _isMyTurn && _ludoPendingDice != null ? () => _ludoMove(i),
      child: Text('🔵 ' + (i + 1).toString() + ': ' + (_ludo[i] == -1 ? 'قاعدة' : _ludo[i].toString() + '/56')),
    ))),
    const SizedBox(height: 8),
    Text('تحتاج 6 للخروج • الوصول يتطلب 56 • قطع الخصم يمكن إعادتها خارج الخانات الآمنة'),
    const SizedBox(height: 8),
    LinearProgressIndicator(value: _ludo.fold<int>(0, (a, b) => a + max(0, b)) / 224),
  ])));

  Widget _unoBoard() => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('اللون الحالي: ' + _unoColor + ' • يدك: ' + _unoHand.length.toString() + ' • الخصم: ' + _unoCpu.length.toString()),
    const SizedBox(height: 8), Text('آخر بطاقة: ' + _unoDiscard.last),
    const SizedBox(height: 8),
    Wrap(spacing: 6, runSpacing: 6, children: List.generate(_unoHand.length, (i) => ChoiceChip(selected: _unoSelected == i, label: Text(_unoHand[i]), onSelected: (_) => setState(() => _unoSelected = i)))),
    const SizedBox(height: 8),
    Row(children: [
      Expanded(child: FilledButton.tonal(onPressed: _isMyTurn && _unoPlayerTurn && _unoHand.isNotEmpty ? () => _unoPlay(_unoSelected) : null, child: const Text('العب'))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton(onPressed: _isMyTurn && _unoPlayerTurn ? _unoDraw : null, child: const Text('اسحب'))),
    ]),
    const SizedBox(height: 8), const Text('تطابق اللون أو الرقم/الرمز. Wild يغيّر اللون، و +2/Skip/Reverse تؤثر في الدور.'),
  ])));

  Widget _crimeBoard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('القضية ' + _crimeCase.toString() + ' • المرحلة ' + _crimePhase.toString() + '/4', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8), Text('الأدلة: ' + _crimeEvidence.toString() + '/5 • نقاط التحقيق: ' + _crimeScore.toString()),
    const SizedBox(height: 8), LinearProgressIndicator(value: _crimeEvidence / 5),
    const SizedBox(height: 10), Text(_crimeCollected.isEmpty ? 'لم تجمع أدلة بعد.' : _crimeCollected.join(' • ')),
    if (_crimeSuspect.isNotEmpty) Text('المشتبه: ' + _crimeSuspect),
    const SizedBox(height: 8), const Text('المراحل: مسرح الجريمة → الأدلة → التحليل → الاتهام → قضية جديدة.'),
  ])));

  Widget _controls() {
    if (_localIndex == 4) return _choiceCard('اختر زاوية التسديد', ['يسار','وسط','يمين'], (i) { if (_onlineMatch) { _submitFlagshipAction('shoot', {'lane': i}); return; } setState(() { _round++; if (_rng.nextInt(3) != i) { _score += 30; _message = '⚽ تسديدة ناجحة'; } else { _message = '🧤 الحارس تصدى'; } }); });
    if (_localIndex == 5) return _choiceCard('اختر الرمية', ['2 نقاط','3 نقاط','Fadeaway'], (i) { if (_onlineMatch) { _submitFlagshipAction('shot', {'shot': i}); return; } setState(() { _round++; final chance = i == 1 ? .55 : .72; if (_rng.nextDouble() < chance) { final p = i == 1 ? 3 : 2; _score += p * 10; _message = '🏀 رمية ناجحة: ' + p.toString(); } else { _message = '🏀 ضاعت الرمية'; } }); });
    if (_localIndex == 6) return _choiceCard('اختر حركة الملاكمة', ['Jab','Hook','Dodge'], (i) { if (_onlineMatch) { _submitFlagshipAction('boxing', {'move': i}); return; } setState(() { if (i == 2) { _energy = min(100, _energy + 12); _message = '🥊 مراوغة +12 طاقة'; } else { _boxingTurn(); } }); });
    if (_localIndex == 9) return _choiceCard('اختر المسار', ['يسار','وسط','يمين'], (i) { if (_onlineMatch) { _submitFlagshipAction('steer', {'lane': i}); return; } setState(() { _distance += i == 1 ? 8 : 5; _racingTurn(); }); });
    return const SizedBox.shrink();
  }

  Widget _choiceCard(String title, List<String> options, void Function(int) onTap) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 8),
    Wrap(spacing: 8, children: List.generate(options.length, (i) => FilledButton.tonal(onPressed: _hp > 0 && _isMyTurn ? () { onTap(i); if (!_onlineMatch) { _saveProgress(); _syncGameState(); } } : null, child: Text(options[i])))),
  ])));

  Widget _actionBoard() {
    final icon = ['⚽','🏀','🥊','⚔️','🥷','🏎️'][_localIndex - 4];
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Text(icon + ' ساحة اللعب', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12), LinearProgressIndicator(value: _hp / 100), const SizedBox(height: 8),
      Text('HP ' + _hp.toString() + ' • طاقة ' + _energy.toString() + ' • الجولة ' + _round.toString() + ' • النقاط ' + _score.toString()),
      if (_localIndex == 9) Text('المسافة: ' + _distance.toString() + 'm'),
    ])));
  }
}
