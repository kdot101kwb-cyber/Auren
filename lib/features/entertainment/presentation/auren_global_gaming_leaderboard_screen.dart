import 'package:flutter/material.dart';
import '../data/auren_game_multiplayer.dart';

class AurenGlobalGamingLeaderboardScreen extends StatefulWidget {
  const AurenGlobalGamingLeaderboardScreen({super.key});
  @override
  State<AurenGlobalGamingLeaderboardScreen> createState() => _AurenGlobalGamingLeaderboardScreenState();
}

class _AurenGlobalGamingLeaderboardScreenState extends State<AurenGlobalGamingLeaderboardScreen> {
  final _multiplayer = AurenGameMultiplayer();
  bool _season = false;
  bool _loading = true;
  List<Map<String, dynamic>> _entries = const [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await _multiplayer.getGlobalGamingLeaderboard(limit: 30, season: _season);
    if (!mounted) return;
    setState(() { _entries = entries; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌍 AUREN Gaming'),
        actions: [
          IconButton(
            tooltip: _season ? 'Lifetime' : 'Current Season',
            onPressed: () { setState(() => _season = !_season); _load(); },
            icon: Icon(_season ? Icons.calendar_month : Icons.public),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
                ? ListView(children: const [SizedBox(height: 220), Center(child: Text('لا توجد نتائج مسجلة بعد'))])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final e = _entries[index];
                      final rank = (e['rank'] as num?)?.toInt() ?? index + 1;
                      final rating = (e['rating'] as num?)?.toInt() ?? 1000;
                      final matches = (e['matches'] as num?)?.toInt() ?? 0;
                      final wins = (e['wins'] as num?)?.toInt() ?? 0;
                      final games = (e['gamesPlayed'] as num?)?.toInt() ?? 0;
                      final winRate = e['winRate'] ?? 0;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text('#$rank')),
                          title: Text('Player ${e['playerId'] ?? '—'}', maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('⭐ $rating  •  🏆 $wins  •  🎮 $matches  •  🌐 $games'),
                          trailing: Text('$winRate%'),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
