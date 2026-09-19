import 'package:flutter/material.dart';
import 'action_center_screen.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/goals/goal_repository.dart';
import '../../../services/memory/memory_repository.dart';
import 'memory_screen.dart';
import '../../agents/presentation/agent_hub_screen.dart';
import 'goals_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';

class PersonalAiScreen extends StatefulWidget {
  const PersonalAiScreen({super.key});

  @override State<PersonalAiScreen> createState() => _PersonalAiScreenState();
}

class _PersonalAiScreenState extends State<PersonalAiScreen> {
  final _auth = FirebaseAurenAuthService();
  final _goals = GoalRepository();
  final _memory = MemoryRepository();

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUserId;
    return Scaffold(
    appBar: AppBar(title: const Text('Personal AI')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (uid != null) ...[
          StreamBuilder(stream: _goals.watch(uid), builder: (_, s) => _summaryTile(context, Icons.flag_outlined, 'Goals', s.hasData ? '${s.data!.length} أهداف محفوظة' : 'جاري التحميل…', const AurenGoalsScreen())),
          StreamBuilder(stream: _memory.watch(uid), builder: (_, s) => _summaryTile(context, Icons.psychology_outlined, 'Memory', s.hasData ? '${s.data!.where((m) => m.enabled).length} ذكريات مفعّلة' : 'جاري التحميل…', const AurenMemoryScreen())),
          const SizedBox(height: 8),
        ],
        const Text('What do you want to achieve?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('حوّل الهدف إلى خطوات، ثم نفّذها بإذنك.'),
        const SizedBox(height: 24),
        _tile(context, Icons.flag_outlined, 'Goal → Reality', 'حوّل الهدف إلى خطة قابلة للتنفيذ.', const AurenGoalsScreen()),
        _tile(context, Icons.check_circle_outline, 'Action Center', 'الأوامر الحساسة تحتاج موافقتك.', const AurenActionCenterScreen()),
        _tile(context, Icons.psychology_outlined, 'AI Memory', 'ذاكرة شخصية تحت تحكمك.', const AurenMemoryScreen()),
        _tile(context, Icons.auto_awesome, 'One Prompt', 'قل لـ AUREN ما تريد وسنحوّله إلى خطوات.', const MessengerScreen(initialPrompt: 'حوّل هذا الهدف إلى خطوات عملية ونفّذ ما يحتاج موافقتي.')),
        _tile(context, Icons.radar, 'Opportunity Radar', 'اكتشف فرصًا مرتبطة بأهدافك ومهاراتك.', const MessengerScreen(initialPrompt: 'ابحث لي عن فرص مناسبة لأهدافي ومهاراتي، ورتّبها حسب مدى التطابق.')),
        _tile(context, Icons.smart_toy_outlined, 'AUREN Agents', 'Marketplace + A2A + Trust + Wallet.', const AurenAgentHubScreen()),
      ],
    ),
  );
  }

  static Widget _summaryTile(BuildContext context, IconData icon, String title, String subtitle, Widget page) => Card(child: ListTile(
    leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
  ));

  static Widget _tile(BuildContext context, IconData icon, String title, String subtitle, [Widget? page]) =>
      Card(child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: page == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ));
}
