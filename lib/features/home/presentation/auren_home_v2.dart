import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/goals/goal_repository.dart';
import '../../core/models/goal.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../personal_ai/presentation/personal_ai_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../search/presentation/global_search_screen.dart';
import 'more_screen.dart';
import 'core_five_screen.dart';
import 'core_five_screen.dart';
import '../../saved/presentation/saved_center_screen.dart';

class AurenHomeV2 extends StatelessWidget {
  const AurenHomeV2({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
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
        if (uid != null)
          StreamBuilder<List<AurenGoal>>(
            stream: GoalRepository().watch(uid),
            builder: (context, snapshot) {
              final goals = (snapshot.data ?? const <AurenGoal>[]).where((g) => g.status == 'active').take(3).toList();
              if (goals.isEmpty) return _goalEmpty(context);
              final average = goals.fold<int>(0, (sum, g) => sum + g.progress) ~/ goals.length;
              return _goalProgress(context, goals, average);
            },
          )
        else
          _goalEmpty(context),
        const SizedBox(height: 12),
        _card(context, Icons.auto_awesome, 'AUREN AI', 'اسأل، خطط، وأنجز.', const MessengerScreen()),
        _card(context, Icons.explore_outlined, 'Discover', 'ناس، أماكن، محتوى وفرص حولك.', const AurenDiscoverScreen()),
        _card(context, Icons.chat_bubble_outline, 'Messenger', 'تواصل مع الناس وAUREN AI.', const MessengerScreen()),
        _card(context, Icons.flag_outlined, 'Goal → Reality', 'حوّل الهدف إلى خطوات.', const PersonalAiScreen()),
        _card(context, Icons.bookmark_outline, 'Saved', 'كل المحتوى الذي حفظته في AUREN.', const AurenSavedCenterScreen()),
        const SizedBox(height: 12),
        Card(child: ListTile(
          leading: const Icon(Icons.layers_outlined),
          title: const Text('AUREN Core 5'),
          subtitle: const Text('AI • Social • Business • Marketplace • Creator'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenCoreFiveScreen())),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.more_horiz),
          title: const Text('More'),
          subtitle: const Text('Pulse • Business • Marketplace • Education • Travel • Entertainment • Agents'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenMoreScreen())),
        )),
      ],
    ),
  );
  }

  Widget _goalEmpty(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: const Text('ابدأ هدفك الأول'),
          subtitle: const Text('حوّل فكرة واحدة إلى خطة قابلة للتنفيذ مع AUREN.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalAiScreen())),
        ),
      );

  Widget _goalProgress(BuildContext context, List<AurenGoal> goals, int average) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [const Icon(Icons.track_changes), const SizedBox(width: 8), const Expanded(child: Text('Goal progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), Text('$average%')]),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: average.clamp(0, 100) / 100),
              const SizedBox(height: 6),
              ...goals.map((goal) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(goal.progress.clamp(0, 100).toString() + '%'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalAiScreen())),
              )),
            ],
          ),
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