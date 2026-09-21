import 'package:flutter/material.dart';

import '../../personal_ai/presentation/personal_ai_screen.dart';
import '../../social/presentation/timeline_screen.dart';
import '../../business/presentation/business_screen.dart';
import '../../marketplace/presentation/marketplace_screen.dart';
import '../../creator/presentation/creator_screen.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/goals/goal_repository.dart';
import '../../../services/social/post_repository.dart';
import '../../../services/business/business_repository.dart';
import '../../../services/marketplace/marketplace_repository.dart';
import '../../../services/creator/creator_repository.dart';

class AurenCoreFiveScreen extends StatelessWidget {
  const AurenCoreFiveScreen({super.key});

  static const modules = <_CoreModule>[
    _CoreModule('Personal AI','الذكاء الشخصي: أهداف، ذاكرة، فرص وتحويل الفكرة إلى خطوة.',Icons.auto_awesome),
    _CoreModule('Social / Pulse','تواصل، نشر، تفاعل، أفكار وفرص داخل شبكة AUREN.',Icons.dynamic_feed_outlined),
    _CoreModule('Business','شركات، متاجر، خدمات وفرص نمو وربط مباشر بالعملاء.',Icons.storefront_outlined),
    _CoreModule('Marketplace','اكتشف المنتجات والخدمات، اشترِ، بع، وتابع الطلبات.',Icons.shopping_bag_outlined),
    _CoreModule('Creator Studio','أنشئ المحتوى، أدِر المسودات، وانشر وطوّر جمهورك.',Icons.video_camera_back_outlined),
  ];

  Widget _page(String title) {
    switch (title) {
      case 'Personal AI': return const PersonalAiScreen();
      case 'Social / Pulse': return const AurenTimelineScreen();
      case 'Business': return const AurenBusinessScreen();
      case 'Marketplace': return const AurenMarketplaceScreen();
      case 'Creator Studio': return const AurenAURENCreatorStudioScreen();
      default: return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAurenAuthService().currentUserId;
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Core 5')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text('أول 5 وحدات أساسية',style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('هذه هي الطبقة التي تجمع الذكاء الشخصي، التواصل، الأعمال، التجارة وصناعة المحتوى في تجربة واحدة.'),
          const SizedBox(height: 18),
          if (uid != null) _liveOverview(context, uid),
          if (uid != null) const SizedBox(height: 14),
          _crossModuleFlow(context),
          const SizedBox(height: 14),
          ...modules.asMap().entries.map((entry) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(child: Text('${entry.key + 1}')),
              title: Row(children: [
                Icon(entry.value.icon, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(entry.value.title, style: const TextStyle(fontWeight: FontWeight.bold))),
              ]),
              subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(entry.value.description)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _page(entry.value.title))),
            ),
          )),
        ],
      ),
    );
  }
  Widget _liveOverview(BuildContext context, String uid) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Core Signals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StreamBuilder(stream: GoalRepository().watch(uid), builder: (_, s) => _signal(Icons.flag_outlined, 'Goals', s.data?.where((g) => g.status == 'active').length.toString() ?? '…')),
                StreamBuilder(stream: PostRepository().watchFeed(), builder: (_, s) => _signal(Icons.dynamic_feed_outlined, 'Pulse', s.data?.length.toString() ?? '…')),
                StreamBuilder(stream: BusinessRepository().watchPublic(), builder: (_, s) => _signal(Icons.storefront_outlined, 'Business', s.data?.length.toString() ?? '…')),
                StreamBuilder(stream: MarketplaceRepository().watchPublic(), builder: (_, s) => _signal(Icons.shopping_bag_outlined, 'Market', s.data?.length.toString() ?? '…')),
                StreamBuilder(stream: CreatorRepository().watchDrafts(uid), builder: (_, s) => _signal(Icons.video_camera_back_outlined, 'Drafts', s.data?.length.toString() ?? '…')),
              ],
            ),
            const SizedBox(height: 12),
            const Text('الوحدات الخمسة الآن مرتبطة ببياناتها الحقيقية، ويمكن تطويرها فوق نفس السياق بدل أن تعمل كجزر منفصلة.'),
          ],
        ),
      ),
    );
  }

  Widget _crossModuleFlow(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.hub_outlined),
                SizedBox(width: 8),
                Expanded(child: Text('Cross-module flows', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 6),
              const Text('الوحدات الخمسة ما بتشتغل كجزر منفصلة. ابدأ من أي نقطة وخلي AUREN يربط الخطوة التالية.'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.flag_outlined, size: 18),
                    label: const Text('Goal → Pulse'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenTimelineScreen())),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.lightbulb_outline, size: 18),
                    label: const Text('Idea → Business'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenBusinessScreen())),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.storefront_outlined, size: 18),
                    label: const Text('Business → Market'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenMarketplaceScreen())),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: const Text('Market → Creator'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenAURENCreatorStudioScreen())),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Ask AUREN'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen(initialPrompt: 'اربط لي أهدافي مع Pulse وBusiness وMarketplace وCreator Studio، واقترح لي مسارًا عمليًا واحدًا للخطوة التالية.'))),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  static Widget _signal(IconData icon, String label, String value) => Chip(
        avatar: Icon(icon, size: 18),
        label: Text('$label: $value'),
      );
}

class _CoreModule {
  final String title;
  final String description;
  final IconData icon;
  const _CoreModule(this.title, this.description, this.icon);
}
