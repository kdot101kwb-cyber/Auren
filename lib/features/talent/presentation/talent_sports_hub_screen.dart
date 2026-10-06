import 'package:flutter/material.dart';
import '../../../services/talent/talent_sports_data_service.dart';
import '../../../services/talent/talent_sports_directory_service.dart';
import '../../../services/talent/talent_sports_trust_service.dart';
import 'talent_sports_entity_screen.dart';
import 'talent_sports_match_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenTalentSportsHubScreen extends StatefulWidget {
  const AurenTalentSportsHubScreen({super.key});
  @override
  State<AurenTalentSportsHubScreen> createState() => _AurenTalentSportsHubScreenState();
}

class _AurenTalentSportsHubScreenState extends State<AurenTalentSportsHubScreen> {
  final _controller = TextEditingController();
  final _service = TalentSportsDataService();
  final _directory = TalentSportsDirectoryService();
  final _trust = TalentSportsTrustService();

  String _mode = 'teams';
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _results = const [];
  String _directoryMode = '';

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _directoryMode = '';
    });
    try {
      final results = switch (_mode) {
        'players' => await _service.searchPlayers(query),
        'matches' => await _service.searchEvents(query.replaceAll(' ', '_')),
        'leagues' => await _service.searchLeagues(query),
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

  Future<void> _loadDirectory(String mode) async {
    setState(() {
      _loading = true;
      _error = null;
      _results = const [];
      _directoryMode = mode;
    });
    try {
      final results = mode == 'countries'
          ? await _service.allCountries()
          : mode == 'sports'
              ? await _service.allSports()
              : await _directory.allLeagues();
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sports Hub'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loading
              ? null
              : _directoryMode.isNotEmpty
                  ? () => _loadDirectory(_directoryMode)
                  : _search,
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
                  Text(
                    'Sports Intelligence',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ]),
                const SizedBox(height: 6),
                const Text(
                  'ابحث عن أندية، لاعبين، مباريات ودوريات، أو تصفح دليل الرياضات والدول.',
                ),
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
                    _modeChip('leagues', '🏆 Leagues'),
                  ],
                ),

                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.fact_check_outlined, size: 18),
                      label: const Text('Sports Truth AI'),
                      onPressed: () => _openSportsAi('تحقق من معلومة رياضية. فرّق بين البيان الرسمي ومصدر البيانات المرخص والصحفي الموثوق والمصدر الإعلامي والمنشور غير المؤكد. لا تخترع مصادر أو أدلة.'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.account_tree_outlined, size: 18),
                      label: const Text('Source Graph'),
                      onPressed: () => _openSportsAi('حلل Source Graph لمعلومة رياضية: المصدر الأول إن كان معروفاً، من أكدها، من صححها أو نفاها، وما الأدلة المطلوبة. لا تخترع أي علاقة أو مصدر.'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.science_outlined, size: 18),
                      label: const Text('What-If Lab'),
                      onPressed: () => _openSportsInnovation(
                        'What-If Sports Lab',
                        'حلل سيناريو رياضي افتراضي مع توضيح الفرضيات والآثار المحتملة والبيانات الناقصة، ولا تقدمه كتوقع مؤكد.',
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.route_outlined, size: 18),
                      label: const Text('Career Map'),
                      onPressed: () => _openSportsInnovation(
                        'Sports Career Map',
                        'أنشئ خريطة مسار رياضي واقعية من المستوى الحالي إلى الفرص المحتملة، مع المهارات والأدلة والخطوات التالية، دون ضمان النجاح.',
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.folder_special_outlined, size: 18),
                      label: const Text('Evidence Locker'),
                      onPressed: () => _openSportsInnovation(
                        'Sports Evidence Locker',
                        'حلل الأدلة الرياضية التي أقدمها، وميّز بين المصدر الواضح والإقرار الذاتي وما يحتاج تحققاً، واقترح أسئلة التحقق.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sports Directory',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'استكشف الدول والدوريات أولاً، ثم انتقل إلى الأندية واللاعبين.',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _directoryChip('countries', '🌍 Countries'),
                    _directoryChip('leagues', '🏆 All Leagues'),
                    _directoryChip('sports', '🏅 Sports'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _sportsTrustCard(),
        const SizedBox(height: 12),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        if (_error != null)
          Card(
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
              child: Text('اكتب اسم نادي أو لاعب أو مباراة للبدء، أو افتح Sports Directory.'),
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


  void _openSportsAi(String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)),
    );
  }

  void _openSportsInnovation(String title, String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessengerScreen(initialPrompt: '$title\\n\\n$prompt'),
      ),
    );
  }


    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)),
    );
  }

  Widget _sportsTrustCard() {
    final trust = _trust.forEntity(type: 'events');
    return Card(
      child: ListTile(
        leading: const Icon(Icons.fact_check_outlined),
        title: Text(trust.label + ' • ' + trust.trustLevel),
        subtitle: Text(
          trust.sourceName + '\n' + trust.coverage + '\n' + trust.guidanceFor(trust.sourceName),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _modeChip(String value, String label) => ChoiceChip(
    label: Text(label),
    selected: _mode == value && _directoryMode.isEmpty,
    onSelected: (_) => setState(() {
      _mode = value;
      _results = const [];
      _error = null;
      _directoryMode = '';
    }),
  );

  Widget _directoryChip(String value, String label) => ChoiceChip(
    label: Text(label),
    selected: _directoryMode == value,
    onSelected: (_) => _loadDirectory(value),
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

  Future<void> _browseCountry(String country) async {
    final sportController = TextEditingController();
    final sport = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('رياضات $country'),
        content: TextField(
          controller: sportController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'اسم الرياضة',
            hintText: 'Football',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              sportController.text.trim(),
            ),
            child: const Text('استكشف'),
          ),
        ],
      ),
    );
    sportController.dispose();
    if (!mounted || sport == null || sport.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = const [];
      _directoryMode = 'country_teams';
    });
    try {
      final results = await _directory.teamsByCountryAndSport(
        country: country,
        sport: sport,
      );
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _resultCard(BuildContext context, Map<String, dynamic> item) {
    if (_directoryMode == 'countries') {
      final country = (item['name_en'] ?? item['name'] ?? 'Country').toString();
      return Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.public)),
          title: Text(country),
          subtitle: const Text('اختر رياضة لعرض الأندية المتاحة'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _browseCountry(country),
        ),
      );
    }

    final isDirectoryLeague = _directoryMode == 'leagues';
    final isDirectorySport = _directoryMode == 'sports';
    final title = isDirectoryLeague
        ? (item['strLeague'] ?? 'League').toString()
        : isDirectorySport
            ? (item['strSport'] ?? 'Sport').toString()
        : _mode == 'players'
            ? (item['strPlayer'] ?? 'Player').toString()
            : _mode == 'matches'
                ? (item['strEvent'] ?? 'Match').toString()
                : (item['strTeam'] ?? 'Club').toString();

    final description = _localizedDescription(
      item,
      Localizations.localeOf(context).languageCode,
    );
    final subtitle = _mode == 'matches'
        ? '${item['dateEvent'] ?? ''} ${item['strTime'] ?? ''}'.trim()
        : '${item['strSport'] ?? ''} • ${item['strLeague'] ?? item['strNationality'] ?? ''}'.trim();
    final image = (isDirectoryLeague || isDirectorySport || _mode == 'leagues')
        ? (item['strBadge'] ?? item['strLogo'])
        : (_mode == 'players' ? item['strThumb'] : item['strBadge']);
    final imageUrl = image?.toString() ?? '';

    final id = isDirectoryLeague
        ? item['idLeague']
        : isDirectorySport
            ? item['idSport']
        : _mode == 'players'
            ? item['idPlayer']
            : item['idTeam'] ?? item['idLeague'];

    final type = isDirectoryLeague
        ? 'leagues'
        : isDirectorySport
            ? 'sports'
            : _mode;

    return Card(
      child: ListTile(
        leading: imageUrl.isEmpty
            ? const CircleAvatar(child: Icon(Icons.sports))
            : CircleAvatar(backgroundImage: NetworkImage(imageUrl)),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          description.isEmpty
              ? (subtitle.isEmpty ? 'Sports data' : subtitle)
              : '$subtitle\n$description',
        ),
        trailing: id?.toString().isNotEmpty ?? false
            ? const Icon(Icons.chevron_right)
            : null,
        onTap: isDirectorySport
            ? null
            : _mode == 'matches' && _directoryMode.isEmpty
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AurenSportsMatchScreen(event: item),
                    ),
                  )
                : (id?.toString().isNotEmpty ?? false)
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AurenSportsEntityScreen(
                            type: type,
                            id: id.toString(),
                            title: title,
                          ),
                        ),
                      )
                    : null
      ),
    );
  }
}
