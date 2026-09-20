import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../personal_ai/presentation/personal_ai_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../search/presentation/global_search_screen.dart';
import '../../social/presentation/timeline_screen.dart';
import '../../agents/presentation/agent_hub_screen.dart';
import 'more_screen.dart';

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
        Text(_greeting(), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('AUREN يتكيف معك، وليس العكس.'),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 25, child: Icon(Icons.auto_awesome)),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What should we do next?', style: TextStyle(fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text('قل لـ AUREN هدفك الآن وسنحوّله إلى خطوة عملية.'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Ask AUREN',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen(initialPrompt: 'ما أفضل خطوة أقدر أعملها الآن؟'))),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _card(context, Icons.auto_awesome, 'AUREN AI', 'اسأل، خطط، وأنجز.', const MessengerScreen()),
        _card(context, Icons.explore_outlined, 'Discover', 'ناس، أماكن، محتوى وفرص حولك.', const AurenDiscoverScreen()),
        _card(context, Icons.chat_bubble_outline, 'Messenger', 'تواصل مع الناس وAUREN AI.', const MessengerScreen()),
        _card(context, Icons.flag_outlined, 'Goal → Reality', 'حوّل هدفك إلى خطوات.', const PersonalAiScreen()),
        const SizedBox(height: 12),
        Card(child: ListTile(
          leading: const Icon(Icons.dynamic_feed_outlined),
          title: const Text('Pulse'),
          subtitle: const Text('شارك، تفاعل واكتشف ما يحدث الآن.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenTimelineScreen())),
        )),
        const SizedBox(height: 4),
        Card(child: ListTile(
          leading: const Icon(Icons.smart_toy_outlined),
          title: const Text('AUREN Agents'),
          subtitle: const Text('وكلاء، Marketplace، A2A، Trust وWallet.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenAgentHubScreen())),
        )),
        const SizedBox(height: 4),
        Card(child: ListTile(
          leading: const Icon(Icons.more_horiz),
          title: const Text('More'),
          subtitle: const Text('Business • Marketplace • Education • Travel • Entertainment'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenMoreScreen())),
        )),
      ],
    ),
  );

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static Widget _card(BuildContext c, IconData i, String t, String s, [Widget? page]) =>
      Card(child: ListTile(
        leading: Icon(i),
        title: Text(t),
        subtitle: Text(s),
        trailing: const Icon(Icons.chevron_right),
        onTap: page == null ? null : () => Navigator.push(c, MaterialPageRoute(builder: (_) => page)),
      ));
}