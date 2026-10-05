import 'dart:async';
import 'package:flutter/material.dart';
import '../data/auren_game_multiplayer.dart';

class AurenLiveSpectatorScreen extends StatefulWidget {
  final String lobbyId;
  final int gameIndex;
  const AurenLiveSpectatorScreen({super.key, required this.lobbyId, required this.gameIndex});
  @override State<AurenLiveSpectatorScreen> createState() => _AurenLiveSpectatorScreenState();
}

class _AurenLiveSpectatorScreenState extends State<AurenLiveSpectatorScreen> {
  final _api = AurenGameMultiplayer();
  Timer? _poller;\n  StreamSubscription<Map<String, dynamic>?>? _sub;
  Map<String, dynamic>? _lobby;
  String? _error;
  String _name(int id) => const {53:'🕵️ Crime Files',54:'⚽ Football Pro',55:'🏀 Basketball Pro',56:'🥊 Boxing Champion',57:'⚔️ Ancient & Modern Wars',58:'🥷 Samurai Legacy',59:'🏎️ AUREN Street Racing'}[id] ?? 'AUREN Game';
  @override void initState() { super.initState(); _sub = _api.watchLobby(widget.lobbyId).listen((v) { if (!mounted) return; setState(() { _lobby = v; _error = null; }); }, onError: (_) { if (mounted) setState(() => _error = 'تعذر تحديث المباراة مباشرة'); }); }
  @override void dispose() { _poller?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final l = _lobby;
    final state = l?['state'] is Map ? Map<String,dynamic>.from(l!['state']) : <String,dynamic>{};
    final players = List<String>.from(l?['players'] ?? const <String>[]);
    final status = l?['status']?.toString() ?? 'waiting';
    return Scaffold(appBar: AppBar(title: const Text('🔴 Live Match')), body: _error != null ? Center(child: Text(_error!)) : l == null ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.live_tv)), title: Text(_name(widget.gameIndex)), subtitle: Text('LIVE • ' + status + ' • Version ' + (l['stateVersion'] ?? 0).toString()))),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Players', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), for (final p in players) ListTile(leading: const Icon(Icons.person), title: Text(p, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: p == l['turnPlayerId'] ? const Text('TURN') : null)]))),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Live State', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), _row('Score', state['score']), _row('Round', state['round']), _row('HP', state['hp']), _row('Streak', state['streak']), _row('Energy', state['energy']), _row('Distance', state['distance']), _row('Status', state['message'])]))),
      const SizedBox(height: 8), const Text('المشاهدة فقط — لا يمكن للمشاهد إرسال حركات أو تغيير نتيجة المباراة.', style: TextStyle(fontWeight: FontWeight.w600)),
    ]));
  }
  Widget _row(String label, dynamic value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.bold))]));
}
