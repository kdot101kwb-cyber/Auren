import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenSportsMatchScreen extends StatelessWidget {
  final Map<String, dynamic> event;
  const AurenSportsMatchScreen({super.key, required this.event});

  String _value(String key) => (event[key] ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final home = _value('strHomeTeam');
    final away = _value('strAwayTeam');
    final eventName = _value('strEvent');
    final title = eventName.isNotEmpty ? eventName : (home.isEmpty ? 'Home' : home) + ' vs ' + (away.isEmpty ? 'Away' : away);
    final score = [_value('intHomeScore'), _value('intAwayScore')].where((v) => v.isNotEmpty).join(' - ');
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
                  const Icon(Icons.sports, size: 48),
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
          const SizedBox(height: 12),
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
}
