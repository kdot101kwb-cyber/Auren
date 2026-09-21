import 'package:flutter/material.dart';
import 'action_center_screen.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/goals/goal_repository.dart';
import '../../../services/memory/memory_repository.dart';
import 'memory_screen.dart';
import '../../agents/presentation/agent_hub_screen.dart';
import '../../../services/core/auren_core_five_repository.dart';
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
        if (uid != null) ...[
          _todayCard(context, uid),
          const SizedBox(height: 12),
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
        _tile(context, Icons.hub_outlined, 'Core 5 Context', 'خلّي AUREN يربط أهدافك وPulse وBusiness وMarketplace وCreator.', null, onTap: () => _openCoreFive(context, uid)),
        _tile(context, Icons.smart_toy_outlined, 'AUREN Agents', 'Marketplace + A2A + Trust + Wallet.', const AurenAgentHubScreen()),
      ],
    ),
  );
  }

  Widget _todayCard(BuildContext context, String uid) => StreamBuilder(
    stream: _goals.watch(uid),
    builder: (context, snapshot) {
      final goals = snapshot.data ?? const <AurenGoal>[];
      final active = goals.where((g) => g.status == 'active').toList();
      final progress = active.isEmpty ? 0 : active.fold<int>(0, (sum, g) => sum + g.progress) ~/ active.length;
      return Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.today_outlined),
              const SizedBox(width: 8),
              const Expanded(child: Text('Today with AUREN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Text('$progress%'),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress.clamp(0, 100) / 100),
            const SizedBox(height: 10),
            Text(active.isEmpty ? 'ابدأ بهدف واحد، وAUREN يساعدك في الخطوة التالية.' : '${active.length} أهداف نشطة • ركّز على خطوة واحدة الآن.'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ActionChip(label: const Text('خطتي الآن'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenActionCenterScreen()))),
              ActionChip(label: const Text('فرصة مناسبة'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen(initialPrompt: 'ابحث لي عن فرصة مناسبة لأهدافي ومهاراتي الآن.')))),
              ActionChip(label: const Text('أهدافي'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenGoalsScreen()))),
            ]),
          ]),
        ),
      );
    },
  );

  static Widget _summaryTile(BuildContext context, IconData icon, String title, String subtitle, Widget page) => Card(child: ListTile(
    leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
  ));

  Future<void> _openCoreFive(BuildContext context, String? uid) async {\n    if (uid == null) return;\n    final messenger = ScaffoldMessenger.of(context);\n    messenger.showSnackBar(const SnackBar(content: Text('جاري جمع سياق الوحدات الخمس...')));\n    try {\n      final snapshot = await AurenCoreFiveRepository().load(uid);\n      if (!context.mounted) return;\n      Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: snapshot.toPrompt())));\n    } catch (e) {\n      if (context.mounted) messenger.showSnackBar(SnackBar(content: Text('تعذر جمع السياق: $e')));\n    }\n  }\n\n  static Widget _tile(BuildContext context, IconData icon, String title, String subtitle, [Widget? page, VoidCallback? onTap]) =>
      Card(child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap ?? (page == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => page))),
      ));
}
