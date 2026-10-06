import 'package:flutter/material.dart';
import '../../../services/talent/talent_sports_data_service.dart';

class AurenTalentSportsHubScreen extends StatefulWidget {
  const AurenTalentSportsHubScreen({super.key});
  @override
  State<AurenTalentSportsHubScreen> createState() => _AurenTalentSportsHubScreenState();
}

class _AurenTalentSportsHubScreenState extends State<AurenTalentSportsHubScreen> {
  final _controller = TextEditingController();
  final _service = TalentSportsDataService();
  String _mode = 'teams';
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _results = const [];

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final results = switch (_mode) {
        'players' => await _service.searchPlayers(query),
        'matches' => await _service.searchEvents(query.replaceAll(' ', '_')),
        _ => await _service.searchTeams(query),
      };
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sports Hub'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loading ? null : _search,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.auto_awesome),
                  SizedBox(width: 8),
                  Text('Sports Intelligence',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 6),
                const Text('ابحث عن أندية، لاعبين أو مباريات من قاعدة رياضية خارجية.'),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: _mode == 'players'
                      ? 'مثال: Mohamed Salah'
                      : _mode == 'matches'
                        ? 'مثال: Arsenal Chelsea'
                        : 'مثال: Arsenal',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: _search,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _modeChip('teams', '🏟️ Clubs'),
                    _modeChip('players', '👤 Players'),
                    _modeChip('matches', '📅 Matches'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_loading) const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        )),
        if (_error != null) Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!),
          ),
        ),
        if (!_loading && _error == null && _results.isNotEmpty)
          ..._results.map((item) => _resultCard(context, item)),
        if (!_loading && _error == null && _results.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('اكتب اسم نادي أو لاعب أو مباراة للبدء.'),
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'المصدر: TheSportsDB. حدود البيانات تعتمد على الخطة المستخدمة.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );

  Widget _modeChip(String value, String label) => ChoiceChip(
    label: Text(label),
    selected: _mode == value,
    onSelected: (_) => setState(() {
      _mode = value;
      _results = const [];
      _error = null;
    }),
  );

  String _localizedDescription(Map<String, dynamic> item, String language) {
    const fields = {
      'ar': 'strDescriptionAR',
      'de': 'strDescriptionDE',
      'es': 'strDescriptionES',
      'fr': 'strDescriptionFR',
      'it': 'strDescriptionIT',
      'pt': 'strDescriptionPT',
      'ru': 'strDescriptionRU',
      'ja': 'strDescriptionJP',
      'nl': 'strDescriptionNL',
      'pl': 'strDescriptionPL',
      'no': 'strDescriptionNO',
      'sv': 'strDescriptionSE',
      'zh': 'strDescriptionCN',
      'en': 'strDescriptionEN',
    };
    final key = fields[language] ?? fields['en']!;
    return (item[key] ?? item['strDescriptionEN'] ?? item['strDescription'] ?? '').toString();
  }

  Widget _resultCard(BuildContext context, Map<String, dynamic> item) {
    final title = _mode == 'players'
      ? (item['strPlayer'] ?? 'Player').toString()
      : _mode == 'matches'
        ? (item['strEvent'] ?? 'Match').toString()
        : (item['strTeam'] ?? 'Club').toString();
    final subtitle = _mode == 'matches'
      ? '${item['dateEvent'] ?? ''} ${item['strTime'] ?? ''}'.trim()
      : '${item['strSport'] ?? ''} • ${item['strLeague'] ?? item['strNationality'] ?? ''}'.trim();
    final image = (_mode == 'players' ? item['strThumb'] : item['strBadge'])?.toString() ?? '';
    return Card(
      child: ListTile(
        leading: image.isEmpty
          ? const CircleAvatar(child: Icon(Icons.sports))
          : CircleAvatar(backgroundImage: NetworkImage(image)),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(description.isEmpty ? (subtitle.isEmpty ? 'Sports data' : subtitle) : '$subtitle\n$description'),
      ),
    );
  }
}
