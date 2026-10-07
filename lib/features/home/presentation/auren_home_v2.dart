import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/i18n/auren_localizations.dart';
import '../../../services/goals/goal_repository.dart';
import '../../../core/models/goal.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../personal_ai/presentation/personal_ai_screen.dart';
import '../../personal_ai/presentation/daily_plan_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../search/presentation/global_search_screen.dart';
import 'more_screen.dart';
import 'core_five_screen.dart';
import '../../../services/core/auren_core_five_repository.dart';
import '../../saved/presentation/saved_center_screen.dart';
import '../../agents/presentation/auren_work_artifacts_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../../services/notifications/notification_repository.dart';
import '../../../services/social/adaptive_discovery_service.dart';
import '../../profile/presentation/adaptive_profile_surface.dart';
import '../../../services/social/adaptive_profile_service.dart';
import '../../../services/social/match_everything_service.dart';
import 'auren_intent_match_card.dart';
import '../../action_center/presentation/action_center_screen.dart';
import '../../suppliers/presentation/auren_supplier_requests_screen.dart';
import '../../safety/presentation/safety_center_screen.dart';

class AurenAdaptiveHomeFocus extends StatelessWidget {
  final String uid;
  final ValueChanged<String> onPrompt;
  const AurenAdaptiveHomeFocus({super.key, required this.uid, required this.onPrompt});
  @override Widget build(BuildContext context) {
    final l = AurenLocalizations.of(context);
    return Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
      title: Text(l.adaptiveHome, style: TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(l.adaptiveHomeSubtitle),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => onPrompt('حلّل وضعي الحالي واقترح لي أفضل خطوة تالية مرتبطة بأهدافي.'),
    ),
  );
  }
}

class AurenHomeV2 extends StatelessWidget {
  const AurenHomeV2({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final l = AurenLocalizations.of(context);
    return Scaffold(
    appBar: AppBar(
      title: const Text('AUREN'),
      actions: [
        StreamBuilder<int>(
          stream: uid == null ? null : NotificationRepository().watchUnreadCount(uid),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return IconButton(
              tooltip: l.notifications,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenNotificationsScreen())),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (count > 0)
                    Positioned(
                      right: -7,
                      top: -7,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenGlobalSearchScreen())),
          icon: const Icon(Icons.search),
          tooltip: l.searchAuren,
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Text(_greeting(), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(l.adaptsToYou),
        const SizedBox(height: 16),
        if (uid != null) ...[
          AurenAdaptiveProfileSurface(
            uid: uid,
            context: AurenProfileContext.unknown,
          ),
          const SizedBox(height: 6),
          AurenAdaptiveActionRail(
            uid: uid,
            context: AurenProfileContext.unknown,
            intent: 'الصفحة الرئيسية وما أحتاجه الآن',
            onPrompt: (prompt) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MessengerScreen(initialPrompt: prompt),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (uid != null)
          AurenAdaptiveHomeFocus(
            uid: uid,
            onPrompt: (prompt) => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)),
            ),
          )
        else
          _homeAurenCard(context, 'ما أفضل خطوة أقدر أعملها الآن؟', 'قل لـ AUREN هدفك الآن وسنحوّله إلى خطوة عملية.'),

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
        if (uid != null)
          FutureBuilder<AurenCoreFiveSnapshot>(
            future: AurenCoreFiveRepository().load(uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final core = snapshot.data!;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.hub_outlined),
                  title: Text('Next move: ${core.nextMove}'),
                  subtitle: Text(
                    '${core.activeGoals} أهداف • ${core.businesses} Business • ${core.products} منتجات • ${core.posts} Pulse • ${core.creatorDrafts} مسودات',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AurenCoreFiveScreen()),
                  ),
                ),
              );
            },
          ),
          if (uid != null)
            FutureBuilder<AurenCoreFiveSnapshot>(
              future: AurenCoreFiveRepository().load(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final core = snapshot.data!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.bolt),
                          const SizedBox(width: 8),
                          Expanded(child: Text(core.actionTitle, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Text('${core.readinessPercent}%'),
                        ]),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: core.readinessPercent / 100),
                        const SizedBox(height: 8),
                        Text(core.nextMove),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await AurenCoreFiveRepository().runCoreFiveBatch(uid);
                              messenger.showSnackBar(const SnackBar(content: Text('تم ربط الهدف بالـCore 5.')));
                            } catch (e) {
                              messenger.showSnackBar(SnackBar(content: Text('تعذر تنفيذ الربط: $e')));
                            }
                          },
                          icon: const Icon(Icons.link),
                          label: const Text('اربط الهدف الآن'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (uid != null)
          FutureBuilder<List<AurenDiscoveryItem>>(
            future: AurenAdaptiveDiscoveryService().findOpportunities(
              uid: uid,
              context: AurenProfileContext.work,
              limit: 5,
            ),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <AurenDiscoveryItem>[];
              if (items.isEmpty) return const SizedBox.shrink();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.radar),
                        SizedBox(width: 8),
                        Text('Opportunity Radar',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 6),
                      const Text('فرص مرتبة حسب سياق ملفك الحالي.'),
                      const SizedBox(height: 8),
                      ...items.take(3).map((item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(item.score.toString()),
                        ),
                        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                      )),
                    ],
                  ),
                ),
              );
            },
          ),
        if (uid != null)
          FutureBuilder<List<AurenDiscoveryItem>>(
            future: AurenAdaptiveDiscoveryService().findPeople(
              uid: uid,
              context: AurenProfileContext.social,
              limit: 5,
            ),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <AurenDiscoveryItem>[];
              if (items.isEmpty) return const SizedBox.shrink();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.people_alt_outlined),
                        SizedBox(width: 8),
                        Text('People to Connect',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 6),
                      const Text('أشخاص قد يتوافقون مع اهتماماتك وسياقك.'),
                      const SizedBox(height: 8),
                      ...items.take(3).map((item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(item.score.toString()),
                        ),
                        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                      )),
                    ],
                  ),
                ),
              );
            },
          ),
        if (uid != null) ...[
          AurenIntentMatchCard(uid: uid),
          const SizedBox(height: 12),
        ],
        if (uid != null)
          FutureBuilder<List<AurenMatchItem>>(
            future: AurenMatchEverythingService().findMatches(
              uid: uid,
              context: AurenProfileContext.unknown,
              limitPerKind: 4,
            ),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <AurenMatchItem>[];
              if (items.isEmpty) return const SizedBox.shrink();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.hub_outlined),
                        SizedBox(width: 8),
                        Text('Match Everything',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 6),
                      const Text('AUREN يربطك بالشخص أو الفرصة أو النشاط أو المنتج أو المحتوى المناسب.'),
                      const SizedBox(height: 8),
                      ...items.take(5).map((item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(child: Text(item.score.toString())),
                        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(item.reasons.join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis),
                      )),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 12),
        _card(context, Icons.auto_awesome, 'AUREN AI', 'اسأل، خطط، وأنجز.', const MessengerScreen()),
        _card(context, Icons.explore_outlined, 'Discover', 'ناس، أماكن، محتوى وفرص حولك.', const AurenDiscoverScreen()),
        _card(context, Icons.chat_bubble_outline, 'Messenger', 'تواصل مع الناس وAUREN AI.', const MessengerScreen()),
        _card(context, Icons.flag_outlined, 'Goal → Reality', 'حوّل الهدف إلى خطوات.', const PersonalAiScreen()),
        _card(context, Icons.today_outlined, 'Daily Plan', 'خطة اليوم المرتبطة بهدفك مع متابعة التنفيذ.', const AurenDailyPlanScreen()),
        _card(context, Icons.bookmark_outline, 'Saved', 'كل المحتوى الذي حفظته في AUREN.', const AurenSavedCenterScreen()),
        _card(context, Icons.work_outline, 'AUREN Work Center', 'الأعمال والمسودات التي أنشأها الوكلاء بعد موافقتك.', const AurenWorkArtifactsScreen()),
        _card(context, Icons.track_changes, 'Action Center', 'تابع كل إجراء بدأته من Match Everything.', const AurenActionCenterScreen()),
        if (uid != null)
          _card(context, Icons.local_shipping_outlined, 'Supplier Requests', 'تابع طلبات التواصل وRFQ وحالاتها وإعادة المحاولة.', const AurenSupplierRequestsScreen()),
        _card(context, Icons.shield_outlined, 'Safety Center', 'الأمان، الحظر، والسلامة عند ضعف الاتصال.', const AurenSafetyCenterScreen()),
        const SizedBox(height: 12),
        Card(child: ListTile(
          leading: const Icon(Icons.layers_outlined),
          title: Text(l.aurenCore5),
          subtitle: const Text('AI • Social • Business • Marketplace • Creator'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenCoreFiveScreen())),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.more_horiz),
          title: Text(l.more),
          subtitle: const Text('Pulse • Business • Marketplace • Education • Travel • Entertainment • Agents'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenMoreScreen())),
        )),
      ],
    ),
  );
  }

  Widget _homeAurenCard(BuildContext context, String prompt, String subtitle) => Card(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What should we do next?', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ask AUREN',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)),
            ),
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    ),
  );

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
              LinearProgressIndicator(value: average.clamp(0, 100).toDouble() / 100),
              const SizedBox(height: 6),
              ...goals.map((goal) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(goal.progress.clamp(0, 100).toInt().toString() + '%'),
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