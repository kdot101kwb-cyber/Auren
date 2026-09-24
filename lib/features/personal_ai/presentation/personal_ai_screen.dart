import 'package:flutter/material.dart';
import 'action_center_screen.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/goals/goal_repository.dart';
import '../../../services/memory/memory_repository.dart';
import 'memory_screen.dart';
import 'memory_timeline_screen.dart';
import 'personal_brief_screen.dart';
import 'next_move_screen.dart';
import 'life_dashboard_screen.dart';
import 'mission_mode_screen.dart';
import 'watchtower_screen.dart';
import 'opportunity_inbox_screen.dart';
import '../../agents/presentation/agent_hub_screen.dart';
import '../../../services/core/auren_core_five_repository.dart';
import 'goals_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../opportunities/presentation/opportunity_ai_screen.dart';
import '../../legal/presentation/legal_ai_screen.dart';

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
          _personalContextCard(context, uid),
          const SizedBox(height: 12),
        ],
        if (uid != null) ...[
          _coreFiveNextCard(context, uid),
          const SizedBox(height: 12),
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
        _tile(context, Icons.history_outlined, 'Memory Timeline', 'شوف كيف تغيّرت ذاكرتك عبر الزمن.', const AurenMemoryTimelineScreen()),
        _tile(context, Icons.article_outlined, 'Personal Brief', 'ملخص شخصي سريع عن أهدافك وأولوياتك الآن.', const AurenPersonalBriefScreen()),
        _tile(context, Icons.next_plan_outlined, 'Next Move', 'يحدد لك AUREN خطوة عملية تالية بناءً على وضعك الحالي.', const AurenNextMoveScreen()),
        _tile(context, Icons.dashboard_outlined, 'Life Dashboard', 'نظرة موحدة على أهدافك وذاكرتك وBusiness وMarketplace وPulse والفرص.', const AurenLifeDashboardScreen()),
        _tile(context, Icons.flag_circle_outlined, 'Mission Mode', 'حوّل هدفك الحالي إلى مهمة مركزة وخطوة أولى.', const AurenMissionModeScreen()),
        _tile(context, Icons.visibility_outlined, 'Watchtower', 'يراقب إشارات واضحة تحتاج انتباهك.', const AurenWatchtowerScreen()),
        _tile(context, Icons.inbox_outlined, 'Opportunity Inbox', 'اجمع الفرص العامة في مكان واحد وحللها مع AUREN.', const AurenOpportunityInboxScreen()),
        _tile(context, Icons.auto_awesome, 'One Prompt', 'قل لـ AUREN ما تريد وسنحوّله إلى خطوات.', const MessengerScreen(initialPrompt: 'حوّل هذا الهدف إلى خطوات عملية ونفّذ ما يحتاج موافقتي.')),
        _tile(context, Icons.radar, 'Opportunity Radar', 'اكتشف فرصًا مرتبطة بأهدافك ومهاراتك.', const AurenOpportunityAiScreen()),
        _tile(context, Icons.gavel_outlined, 'Legal AI', 'افهم المستندات والعقود وأسئلة المراجعة القانونية.', const AurenLegalAiScreen()),
        _tile(context, Icons.hub_outlined, 'Core 5 Context', 'خلّي AUREN يربط أهدافك وPulse وBusiness وMarketplace وCreator.', null, onTap: () => _openCoreFive(context, uid)),
        if (uid != null) _coreFiveBuildCard(context, uid),
        _tile(context, Icons.alt_route_outlined, 'Goal → Content → Opportunity', 'حوّل هدفك إلى محتوى أو منتج أو فرصة Business عبر الوحدات الخمس.', null, onTap: () => _openCoreFive(context, uid)),
        _tile(context, Icons.smart_toy_outlined, 'AUREN Agents', 'Marketplace + A2A + Trust + Wallet.', const AurenAgentHubScreen()),
      ],
    ),
  );
  }


  Widget _personalContextCard(BuildContext context, String uid) => FutureBuilder<AurenPersonalContext>(
    future: PersonalContextRepository().load(uid),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox.shrink();
      final data = snapshot.data!;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.auto_awesome),
                const SizedBox(width: 8),
                const Expanded(child: Text('Personal AI Context', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Text('${data.goals.length} أهداف • ${data.memories.length} ذاكرة'),
              ]),
              const SizedBox(height: 8),
              Text(data.goals.isEmpty
                  ? 'ابدأ بهدف، وAUREN سيستخدمه مع الذاكرة لبناء السياق.'
                  : 'متوسط تقدم أهدافك: ${data.averageProgress}%'),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: data.toPrompt())),
                ),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('اسأل AUREN باستخدام سياقي'),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _coreFiveNextCard(BuildContext context, String uid) => FutureBuilder<AurenCoreFiveSnapshot>(
    future: AurenCoreFiveRepository().load(uid),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox.shrink();
      final core = snapshot.data!;
      return Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.route_outlined)),
          title: Text(core.actionTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(core.nextMove),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: core.toPrompt())),
          ),
        ),
      );
    },
  );

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

  Widget _coreFiveBuildCard(BuildContext context, String uid) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.rocket_launch_outlined)),
      title: const Text('Build My Core 5 Loop', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text('حوّل هدفك الحالي إلى مسودة Creator ومنشور Pulse في خطوة واحدة.'),
      trailing: const Icon(Icons.play_arrow),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(const SnackBar(content: Text('AUREN يبني الحلقة من هدفك الحالي...')));
        try {
          final result = await AurenCoreFiveRepository().runCoreFiveBatch(uid);
          if (!context.mounted) return;
          messenger.showSnackBar(SnackBar(
            content: Text(result.draftId == null
                ? 'أضف هدفًا نشطًا أولًا من Goal → Reality.'
                : 'تم ربط هدفك بـ Creator Studio وPulse.'),
          ));
        } catch (e) {
          if (context.mounted) messenger.showSnackBar(SnackBar(content: Text('تعذر تنفيذ الحلقة: $e')));
        }
      },
    ),
  );

  static Widget _summaryTile(BuildContext context, IconData icon, String title, String subtitle, Widget page) => Card(child: ListTile(
    leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
  ));

  Future<void> _openCoreFive(BuildContext context, String? uid) async {
    if (uid == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('جاري جمع سياق الوحدات الخمس...')));
    try {
      final snapshot = await AurenCoreFiveRepository().load(uid);
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: snapshot.toPrompt())));
    } catch (e) {
      if (context.mounted) messenger.showSnackBar(SnackBar(content: Text('تعذر جمع السياق: $e')));
    }
  }

  static Widget _tile(BuildContext context, IconData icon, String title, String subtitle, [Widget? page, VoidCallback? onTap]) =>
      Card(child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap ?? (page == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => page))),
      ));
}
