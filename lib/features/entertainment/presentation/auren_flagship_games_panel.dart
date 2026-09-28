import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/auren_game_progress.dart';
import '../data/auren_game_multiplayer.dart';

class AurenFlagshipGamesPanel extends StatefulWidget {
  final int gameIndex;
  const AurenFlagshipGamesPanel({super.key, required this.gameIndex});
  @override State<AurenFlagshipGamesPanel> createState() => _AurenFlagshipGamesPanelState();
}

class _AurenFlagshipGamesPanelState extends State<AurenFlagshipGamesPanel> {
  final _rng = Random();
  final _multiplayer = AurenGameMultiplayer();
  StreamSubscription<Map<String, dynamic>?>? _lobbySubscription;
  String? _lobbyId;
  String _onlineStatus = 'Offline';
  String? _turnPlayerId;
  int _stateVersion = 0;
  int _localMoveCounter = 0;
  int _score = 0, _round = 0, _hp = 100, _streak = 0, _energy = 100, _distance = 0;
  int _bestScore = 0, _wins = 0, _savedRounds = 0;
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
  }

  Future<void> _loadProgress() async {
    final progress = await AurenGameProgress.load(widget.gameIndex);
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
      gameIndex: widget.gameIndex,
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
    _lobbySubscription?.cancel();
    _multiplayer.leaveLobby();
    super.dispose();
  }

  bool get _onlineMatch => _lobbyId != null;
  bool get _isMyTurn => !_onlineMatch || _turnPlayerId == _multiplayer.playerId;
  String _nextMoveId() => '${_multiplayer.playerId}-${++_localMoveCounter}';

  Map<String, dynamic> _gameState() => {
    'gameIndex': widget.gameIndex,
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
    });
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

  Future<void> _createLobby() async {
    try {
      final id = await _multiplayer.createLobby(gameIndex: widget.gameIndex);
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
      final ok = await _multiplayer.joinLobby(lobbyId: code, gameIndex: widget.gameIndex);
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
      final status = data['status']?.toString() ?? 'waiting';
      final turnText = status == 'playing' ? (_isMyTurn ? 'Your turn' : 'Opponent turn') : 'Waiting';
      setState(() => _onlineStatus = status == 'playing' ? '2 Players • ' + turnText : turnText + ' • ' + players.length.toString() + '/2');
    });
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
    if (oldWidget.gameIndex != widget.gameIndex) {
      unawaited(_leaveLobby());
      _reset();
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
    switch (widget.gameIndex) {
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

  String get _button => ['ارمِ النرد','اسحب قطعة','اسحب بطاقة','تقدم في القضية','سدّد','ارمِ الكرة','هاجم','نفّذ المهمة','نفّذ الحركة','سباق!'][widget.gameIndex];

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(_names[widget.gameIndex], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6), Text('جولة ' + _round.toString() + ' • ⭐ ' + _score.toString() + ' • 🔥 Combo ' + _streak.toString()),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('🌐 ' + _onlineStatus, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (_lobbyId != null) IconButton(onPressed: _leaveLobby, icon: const Icon(Icons.close)),
        ]),
        if (_lobbyId == null) Row(children: [
          Expanded(child: FilledButton.tonal(onPressed: _createLobby, child: const Text('Create Match'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: _joinLobby, child: const Text('Join Match'))),
        ]),
        const SizedBox(height: 8),
        Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Best', _bestScore.toString()),
          _stat('Wins', _wins.toString()),
          _stat('Saved Rounds', _savedRounds.toString()),
        ]),
      ]))),
      const SizedBox(height: 12),
      if (widget.gameIndex == 0) _ludoBoard(),
      if (widget.gameIndex == 1) _dominoBoard(),
      if (widget.gameIndex == 2) _unoBoard(),
      if (widget.gameIndex == 3) _crimeBoard(),
      if (widget.gameIndex >= 4) _actionBoard(),
      if (widget.gameIndex >= 4) _controls(),
      const SizedBox(height: 12),
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

  Widget _dominoBoard() => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('يدك: ' + _dominoHand.length.toString() + ' • الخصم: ' + _dominoCpu.length.toString() + ' • السحب: ' + _dominoPool.length.toString()),
    const SizedBox(height: 8),
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _dominoBoard.map((p) => Padding(padding: const EdgeInsets.only(right: 5), child: Chip(label: Text('🁫 ' + p))).toList())),
    const SizedBox(height: 8), Text('الأطراف: ' + _dominoLeft.toString() + ' | ' + _dominoRight.toString()),
    const SizedBox(height: 8),
    Wrap(spacing: 6, runSpacing: 6, children: List.generate(_dominoHand.length, (i) => FilledButton.tonal(onPressed: _isMyTurn && _dominoPlayerTurn ? () => _dominoPlay(i) : null, child: Text(_dominoHand[i])))),
    const SizedBox(height: 8), const Text('طابق أحد طرفي السلسلة. إذا لم توجد قطعة قانونية استخدم زر السحب.'),
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
    if (widget.gameIndex == 4) return _choiceCard('اختر زاوية التسديد', ['يسار','وسط','يمين'], (i) { if (_onlineMatch) { _submitFlagshipAction('shoot', {'lane': i}); return; } setState(() { _round++; if (_rng.nextInt(3) != i) { _score += 30; _message = '⚽ تسديدة ناجحة'; } else { _message = '🧤 الحارس تصدى'; } }); });
    if (widget.gameIndex == 5) return _choiceCard('اختر الرمية', ['2 نقاط','3 نقاط','Fadeaway'], (i) { if (_onlineMatch) { _submitFlagshipAction('shot', {'shot': i}); return; } setState(() { _round++; final chance = i == 1 ? .55 : .72; if (_rng.nextDouble() < chance) { final p = i == 1 ? 3 : 2; _score += p * 10; _message = '🏀 رمية ناجحة: ' + p.toString(); } else { _message = '🏀 ضاعت الرمية'; } }); });
    if (widget.gameIndex == 6) return _choiceCard('اختر حركة الملاكمة', ['Jab','Hook','Dodge'], (i) { if (_onlineMatch) { _submitFlagshipAction('boxing', {'move': i}); return; } setState(() { if (i == 2) { _energy = min(100, _energy + 12); _message = '🥊 مراوغة +12 طاقة'; } else { _boxingTurn(); } }); });
    if (widget.gameIndex == 9) return _choiceCard('اختر المسار', ['يسار','وسط','يمين'], (i) { if (_onlineMatch) { _submitFlagshipAction('steer', {'lane': i}); return; } setState(() { _distance += i == 1 ? 8 : 5; _racingTurn(); }); });
    return const SizedBox.shrink();
  }

  Widget _choiceCard(String title, List<String> options, void Function(int) onTap) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 8),
    Wrap(spacing: 8, children: List.generate(options.length, (i) => FilledButton.tonal(onPressed: _hp > 0 && _isMyTurn ? () { onTap(i); _saveProgress(); _syncGameState(); } : null, child: Text(options[i])))),
  ])));

  Widget _actionBoard() {
    final icon = ['⚽','🏀','🥊','⚔️','🥷','🏎️'][widget.gameIndex - 4];
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Text(icon + ' ساحة اللعب', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12), LinearProgressIndicator(value: _hp / 100), const SizedBox(height: 8),
      Text('HP ' + _hp.toString() + ' • طاقة ' + _energy.toString() + ' • الجولة ' + _round.toString() + ' • النقاط ' + _score.toString()),
      if (widget.gameIndex == 9) Text('المسافة: ' + _distance.toString() + 'm'),
    ])));
  }
}
