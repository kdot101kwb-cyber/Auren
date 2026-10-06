import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../../services/talent/talent_sports_data_service.dart';
import '../../../services/talent/talent_sports_trust_service.dart';

class AurenSportsMatchScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  const AurenSportsMatchScreen({super.key, required this.event});

  String _value(String key) => (event[key] ?? '').toString().trim();

  @override
  State<AurenSportsMatchScreen> createState() => _AurenSportsMatchScreenState();
}

class _AurenSportsMatchScreenState extends State<AurenSportsMatchScreen> {
  final _service = TalentSportsDataService();
  final _trust = TalentSportsTrustService();
  String _homeBadge = '';
  String _awayBadge = '';
  bool _badgesLoading = false;

  String _value(String key) => (widget.event[key] ?? '').toString().trim();

  @override
  void initState() {
    super.initState();
    _homeBadge = _value('strHomeTeamBadge');
    _awayBadge = _value('strAwayTeamBadge');
    _loadMissingBadges();
  }

  Future<void> _loadMissingBadges() async {
    if (_homeBadge.isNotEmpty && _awayBadge.isNotEmpty) return;
    if (_badgesLoading) return;
    _badgesLoading = true;
    try {
      final homeId = _value('idHomeTeam');
      final awayId = _value('idAwayTeam');
      if (_homeBadge.isEmpty && homeId.isNotEmpty) {
        final rows = await _service.lookupTeam(homeId);
        if (rows.isNotEmpty) _homeBadge = (rows.first['strBadge'] ?? rows.first['strLogo'] ?? '').toString();
      }
      if (_awayBadge.isEmpty && awayId.isNotEmpty) {
        final rows = await _service.lookupTeam(awayId);
        if (rows.isNotEmpty) _awayBadge = (rows.first['strBadge'] ?? rows.first['strLogo'] ?? '').toString();
      }
      if (mounted) setState(() {});
    } catch (_) {
      // Missing badges must never prevent the match page from opening.
    } finally {
      _badgesLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = _value('strHomeTeam');
    final away = _value('strAwayTeam');
    final eventName = _value('strEvent');
    final title = eventName.isNotEmpty ? eventName : (home.isEmpty ? 'Home' : home) + ' vs ' + (away.isEmpty ? 'Away' : away);
    final score = [_value('intHomeScore'), _value('intAwayScore')].where((v) => v.isNotEmpty).join(' - ');
    final homeBadge = _homeBadge;
    final awayBadge = _awayBadge;
    final round = _value('intRound');
    final venue = _value('strVenue');
    final status = _value('strStatus');
    final trust = _trust.forEntity(type: 'events');
    final truth = _trust.truthSignal(source: trust.sourceName, updatedAt: trust.updatePolicy);
    final details = <MapEntry<String, String>>[
      MapEntry('التاريخ', _value('dateEvent')),
      MapEntry('الوقت', _value('strTime')),
      MapEntry('الحالة', _value('strStatus')),
      MapEntry('الملعب', _value('strVenue')),
      MapEntry('الدوري', _value('strLeague')),
      MapEntry('الرياضة', _value('strSport')),
      MapEntry('الجولة', _value('intRound')),
    ].where((e) => e.value.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Match')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _teamBadge(homeBadge),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900))),
                      _teamBadge(awayBadge),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  if (score.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(score, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  ],
                ],
              ),
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: details.map((e) => ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(e.key),
                  subtitle: Text(e.value),
                )).toList(),
              ),
            ),
          ],
          if (status.isNotEmpty || venue.isNotEmpty || round.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (status.isNotEmpty) Chip(label: Text('Status: ' + status)),
                    if (venue.isNotEmpty) Chip(label: Text('Venue: ' + venue)),
                    if (round.isNotEmpty) Chip(label: Text('Round: ' + round)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MessengerScreen(
                  initialPrompt: 'حلل لي هذه المباراة: ' + title + '. استخدم فقط بيانات المباراة المعروضة، ولا تخترع إحصائيات أو نتيجة غير موجودة.',
                ),
              ),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('حلل المباراة مع AUREN AI'),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(_trust.forEntity(type: 'events').label),
              subtitle: Text(
                _trust.forEntity(type: 'events').sourceName + ' • ' +
                    _trust.forEntity(type: 'events').trustLevel + '\n' +
                    _trust.guidanceFor(_trust.forEntity(type: 'events').sourceName),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.verified_outlined),
              title: Text('Sports data'),
              subtitle: Text('تظهر فقط معلومات المباراة التي يوفرها مصدر البيانات. لا يتم اختراع نتائج أو إحصائيات ناقصة.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamBadge(String url) {
    if (url.isEmpty) return const CircleAvatar(radius: 28, child: Icon(Icons.sports));
    return CircleAvatar(radius: 28, backgroundImage: NetworkImage(url));
  }
}
