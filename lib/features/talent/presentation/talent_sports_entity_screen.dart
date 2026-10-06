import 'package:flutter/material.dart';
import '../../../services/talent/talent_sports_data_service.dart';
import '../../../services/talent/talent_sports_directory_service.dart';
import '../../../services/talent/talent_sports_trust_service.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'talent_sports_match_screen.dart';

class AurenSportsEntityScreen extends StatefulWidget {
  final String type;
  final String id;
  final String title;
  const AurenSportsEntityScreen({
    super.key,
    required this.type,
    required this.id,
    required this.title,
  });

  @override
  State<AurenSportsEntityScreen> createState() => _AurenSportsEntityScreenState();
}

class _AurenSportsEntityScreenState extends State<AurenSportsEntityScreen> {
  final _service = TalentSportsDataService();
  final _directory = TalentSportsDirectoryService();
  final _trust = TalentSportsTrustService();
  Map<String, dynamic>? _item;
  List<Map<String, dynamic>> _next = const [];
  List<Map<String, dynamic>> _last = const [];
  List<Map<String, dynamic>> _related = const [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<Map<String, dynamic>> result;
      if (widget.type == 'players') {
        result = await _service.lookupPlayer(widget.id);
      } else if (widget.type == 'leagues') {
        result = await _service.lookupLeague(widget.id);
      } else {
        result = await _service.lookupTeam(widget.id);
      }
      if (result.isEmpty) {
        throw Exception('Sports profile not found.');
      }

      final item = result.first;
      List<Map<String, dynamic>> next = const [];
      List<Map<String, dynamic>> related = const [];

      if (widget.type == 'teams') {
        next = await _service.teamNextEvents(widget.id);
        try {
          _last = await _service.teamLastEvents(widget.id);
        } catch (_) {
          _last = const [];
        }
        related = await _directory.playersByTeam(widget.id);
      } else if (widget.type == 'leagues') {
        final leagueName = (item['strLeague'] ?? widget.title).toString();
        related = await _directory.teamsByLeague(league: leagueName);
      }

      if (!mounted) return;
      setState(() {
        _item = item;
        _next = next;
        _related = related;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : item == null
                  ? const Center(child: Text('No sports data.'))
                  : _body(context, item),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 42),
              const SizedBox(height: 10),
              Text(_error!),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  Widget _body(BuildContext context, Map<String, dynamic> item) {
    final language = Localizations.localeOf(context).languageCode;
    final description = _service.localized(item, language);
    final image = (item['strThumb'] ?? item['strBadge'] ?? item['strLogo'] ?? '').toString();
    final trust = _trust.forEntity(type: widget.type);
    final truth = _trust.truthSignal(source: trust.sourceName, updatedAt: trust.updatePolicy);
    final subtitle = [
      item['strSport'],
      item['strLeague'],
      item['strNationality'],
      item['strCountry'],
    ].whereType<String>().where((v) => v.trim().isNotEmpty).join(' • ');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (image.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 8,
                    child: Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Colors.black12,
                        child: Center(child: Icon(Icons.sports, size: 48)),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(subtitle),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MessengerScreen(
                                    initialPrompt: 'حلل لي هذا الكيان الرياضي: ${widget.title}. الرياضة: ${item['strSport'] ?? ''}. الدوري: ${item['strLeague'] ?? ''}. الجنسية/الدولة: ${item['strNationality'] ?? item['strCountry'] ?? ''}. الإحصائيات المتاحة: ${_availableStatsPrompt(item)}. استخدم فقط هذه البيانات، واذكر بوضوح أي معلومة غير متوفرة.',
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('حلل مع AUREN AI'),
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(description),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          _trustCard(trust, truth),
          _statsCard(item),
          if (_last.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Recent results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            ..._last.take(10).map(_eventCard),
          ],
          if (_next.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Next matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            ..._next.take(10).map(_eventCard),
          ],
          if (_related.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.type == 'teams' ? 'Players' : 'Clubs',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            ..._related.take(30).map((related) => _relatedCard(context, related)),
          ],
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('AUREN Sports AI'),
              subtitle: const Text(
                'استخدم الصفحة كنقطة انطلاق للتحليل، الإحصائيات والفرص المرتبطة بهذا الكيان.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _availableStatsPrompt(Map<String, dynamic> item) { final keys = ['intPlayed','intAppearances','intGoals','intAssists','intMinutes','strRating','intWeight','intHeight']; return keys.where((k) => item[k] != null && item[k].toString().trim().isNotEmpty).map((k) => '$k=${item[k]}').join(', '); }\n\n  Widget _statsCard(Map<String, dynamic> item) {
    const keys = <String, String>{
      'Matches': 'intPlayed',
      'Appearances': 'intAppearances',
      'Goals': 'intGoals',
      'Assists': 'intAssists',
      'Minutes': 'intMinutes',
      'Rating': 'strRating',
      'Weight': 'intWeight',
      'Height': 'intHeight',
    };
    final rows = <MapEntry<String, String>>[];
    for (final entry in keys.entries) {
      final value = item[entry.value];
      if (value != null && value.toString().trim().isNotEmpty) {
        rows.add(MapEntry(entry.key, value.toString()));
      }
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Available stats', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rows.map((row) => Chip(avatar: const Icon(Icons.insights, size: 18), label: Text(row.key + ': ' + row.value))).toList(),
            ),
            const SizedBox(height: 6),
            const Text('تظهر فقط الإحصائيات التي يوفرها مصدر البيانات لهذا الكيان.', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
  Widget _trustCard(SportsTrustInfo trust, SportsTruthSignal truth) {
    return Card(
      child: ListTile(
        leading: Icon(trust.isOfficial ? Icons.verified : Icons.info_outline),
        title: Text(trust.label + ' • ' + truth.label),
        subtitle: Text(
          trust.sourceName + ' • ' + trust.coverage + '\nآخر تحديث: ' + trust.updatePolicy,
        ),
          const SizedBox(height: 4),
          Text(truth.explanation),
      ),
    );
  }

  Widget _relatedCard(BuildContext context, Map<String, dynamic> item) {
    final isTeam = widget.type == 'leagues';
    final title = isTeam
        ? (item['strTeam'] ?? 'Club').toString()
        : (item['strPlayer'] ?? 'Player').toString();
    final id = isTeam ? item['idTeam'] : item['idPlayer'];
    final image = (isTeam ? item['strBadge'] : item['strThumb'])?.toString() ?? '';

    return Card(
      child: ListTile(
        leading: image.isEmpty
            ? const CircleAvatar(child: Icon(Icons.sports))
            : CircleAvatar(backgroundImage: NetworkImage(image)),
        title: Text(title),
        subtitle: Text(
          [item['strSport'], item['strLeague'], item['strPosition']]
              .whereType<String>()
              .where((v) => v.trim().isNotEmpty)
              .join(' • '),
        ),
        trailing: id?.toString().isNotEmpty ?? false
            ? const Icon(Icons.chevron_right)
            : null,
        onTap: id?.toString().isNotEmpty ?? false
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AurenSportsEntityScreen(
                      type: isTeam ? 'teams' : 'players',
                      id: id.toString(),
                      title: title,
                    ),
                  ),
                )
            : null,
      ),
    );
  }

  Widget _eventCard(Map<String, dynamic> event) {
    final home = (event['strHomeTeam'] ?? '').toString();
    final away = (event['strAwayTeam'] ?? '').toString();
    final score = [
      event['intHomeScore'],
      event['intAwayScore'],
    ].where((v) => v != null).map((v) => v.toString()).join(' - ');
    final date = (event['dateEvent'] ?? '').toString();
    final time = (event['strTime'] ?? '').toString();
    final status = (event['strStatus'] ?? '').toString();
    final venue = (event['strVenue'] ?? '').toString();
    final details = [date, time, status, venue, score].where((v) => v.isNotEmpty).join(' • ');
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event),
        title: Text(
          home.isEmpty && away.isEmpty
              ? (event['strEvent'] ?? 'Match').toString()
              : '$home vs $away',
        ),
        subtitle: Text(details),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AurenSportsMatchScreen(event: event),
          ),
        ),
      ),
    );
  }
}
