import 'package:flutter/material.dart';
import 'action_center_screen.dart';
import 'memory_screen.dart';
import '../../agents/presentation/agent_hub_screen.dart';
import 'goals_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';

class PersonalAiScreen extends StatelessWidget {
  const PersonalAiScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Personal AI')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
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

  static Widget _tile(BuildContext context, IconData icon, String title, String subtitle, [Widget? page]) =>
      Card(child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: page == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ));
}
