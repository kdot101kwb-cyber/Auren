import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../personal_ai/presentation/personal_ai_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../search/presentation/global_search_screen.dart';

class AurenHomeV2 extends StatelessWidget {
  const AurenHomeV2({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('AUREN'),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenGlobalSearchScreen())),
          icon: const Icon(Icons.search),
          tooltip: 'Search AUREN',
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('For You', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('AUREN يتكيف معك، وليس العكس.'),
        const SizedBox(height: 20),
        _card(context, Icons.auto_awesome, 'AUREN AI', 'اسأل، خطط، وأنجز.', const MessengerScreen()),
        _card(context, Icons.explore_outlined, 'Discover', 'ناس، أماكن، محتوى وفرص حولك.', const AurenDiscoverScreen()),
        _card(context, Icons.chat_bubble_outline, 'Messenger', 'تواصل مع الناس وAUREN AI.', const MessengerScreen()),
        _card(context, Icons.flag_outlined, 'Goal → Reality', 'حوّل هدفك إلى خطوات.', const PersonalAiScreen()),
        const SizedBox(height: 12),
        Card(child: ListTile(
          leading: const Icon(Icons.more_horiz),
          title: const Text('More'),
          subtitle: const Text('Business • Marketplace • Education • Travel • Entertainment'),
        )),
      ],
    ),
  );

  static Widget _card(BuildContext c, IconData i, String t, String s, [Widget? page]) =>
      Card(child: ListTile(
        leading: Icon(i),
        title: Text(t),
        subtitle: Text(s),
        trailing: const Icon(Icons.chevron_right),
        onTap: page == null ? null : () => Navigator.push(c, MaterialPageRoute(builder: (_) => page)),
      ));
}