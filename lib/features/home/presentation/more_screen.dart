import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../personal_ai/presentation/personal_ai_screen.dart';
import '../../education/presentation/education_screen.dart';
import '../../travel/presentation/travel_screen.dart';
import '../../entertainment/presentation/entertainment_screen.dart';
import '../../creator/presentation/creator_screen.dart';
import '../../business/presentation/business_screen.dart';
import '../../marketplace/presentation/marketplace_screen.dart';
import '../../agents/presentation/agent_hub_screen.dart';
import '../../real_estate/presentation/real_estate_screen.dart';
import '../../personal_ai/presentation/talent_discovery_screen.dart';
import '../../personal_ai/presentation/universal_search_screen.dart';
import '../../personal_ai/presentation/trust_graph_screen.dart';
import '../../personal_ai/presentation/digital_twin_screen.dart';
import '../../personal_ai/presentation/future_simulator_screen.dart';
import '../../social/presentation/random_connect_screen.dart';
import '../../personal_ai/presentation/local_intelligence_screen.dart';
import '../../social/presentation/timeline_screen.dart';
import '../../social/presentation/saved_pulse_screen.dart';
import '../../saved/presentation/saved_center_screen.dart';
import 'core_ten_screen.dart';
import 'core_five_next_screen.dart';
import 'systems_47_screen.dart';
import '../../suppliers/presentation/auren_supplier_requests_screen.dart';

class AurenMoreScreen extends StatelessWidget {
  const AurenMoreScreen({super.key});

  static const _items = <_MoreItem>[
    _MoreItem('Business', 'شركات، متاجر وخدمات وفرص نمو.', Icons.storefront_outlined, 'ساعدني أكتشف وأطوّر فرص Business مناسبة لي.'),
    _MoreItem('Marketplace', 'اكتشف واشترِ وبِع داخل AUREN.', Icons.shopping_bag_outlined, 'ساعدني أجد ما أحتاجه في Marketplace.'),
    _MoreItem('Education', 'تعلم مهارات عملية خطوة بخطوة.', Icons.school_outlined, 'ساعدني أختار مسار تعلم يناسب هدفي الحالي.'),
    _MoreItem('Travel', 'أماكن، رحلات وتجارب حول العالم.', Icons.flight_takeoff_outlined, 'خطط لي رحلة مناسبة لميزانيتي واهتماماتي.'),
    _MoreItem('Entertainment', 'Series • Music • Gaming • Live.', Icons.play_circle_outline, 'اقترح لي ترفيهًا يناسب مزاجي ووقتي اليوم.'),
    _MoreItem('Creator Studio', 'أنشئ وانشر وطوّر جمهورك.', Icons.video_camera_back_outlined, 'ساعدني أبني خطة Creator Studio ومحتوى مناسب لجمهوري.'),
    _MoreItem('Real Estate', 'عقارات للبيع والإيجار مع بحث ومقارنة ذكية.', Icons.home_work_outlined, 'ساعدني أبحث عن عقار مناسب وقارن الخيارات حسب احتياجي.'),
    _MoreItem('Talent Scout', 'اكتشف المواهب من النشاط العام في Pulse.', Icons.person_search_outlined, 'ساعدني أكتشف المواهب المناسبة لهدفي من نشاط AUREN Pulse.'),
    _MoreItem('Universal Search', 'ابحث في شركات ومنتجات ومنشورات AUREN.', Icons.manage_search_outlined, 'ساعدني أبحث داخل AUREN عن أفضل نتيجة لهدفي.'),
    _MoreItem('Trust Graph', 'إشارات ثقة واضحة وقابلة للمراجعة.', Icons.verified_user_outlined, 'ساعدني أفهم إشارات الثقة المرتبطة بهذا المستخدم.'),
    _MoreItem('Digital Twin', 'ملف ذكي للأهداف والتفضيلات والقيود.', Icons.psychology_outlined, 'ساعدني أستخدم الـDigital Twin في التخطيط.'),
    _MoreItem('Future Simulator', 'جرّب مسارات مختلفة قبل اتخاذ القرار.', Icons.timeline_outlined, 'ساعدني أقارن سيناريوهات مستقبلية لهدفي.'),
    _MoreItem('Random Connect', 'تعرّف على أشخاص حسب اللغة والاهتمام والهدف.', Icons.connect_without_contact_outlined, 'ساعدني أجد أشخاصاً مناسبين للتواصل.'),
  ];

  void _open(BuildContext context, _MoreItem item) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: item.prompt)),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('More')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('AUREN World', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('كل مسارات AUREN في مكان واحد — واختر كيف تريد أن تبدأ.'),
        const SizedBox(height: 18),
        Card(child: ListTile(
          leading: const Icon(Icons.local_shipping_outlined),
          title: const Text('طلبات الموردين'),
          subtitle: const Text('تابع مسودات التواصل وطلبات عروض الأسعار وحالاتها.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenSupplierRequestsScreen())),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.hub_outlined),
          title: const Text('AUREN Core 10'),
          subtitle: const Text('أول 10 أنظمة أساسية متصلة.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenCoreTenScreen())),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.layers_outlined),
          title: const Text('AUREN Core 5 — Next'),
          subtitle: const Text('Discover • Messenger • Education • Travel • Entertainment'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenCoreFiveNextScreen())),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.hub_outlined),
          title: const Text('AUREN — 47 Systems'),
          subtitle: const Text('ربط أنظمة AUREN الـ47 في مسار واحد'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenSystems47Screen())),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.dynamic_feed_outlined),
          title: const Text('Pulse'),
          subtitle: const Text('شارك، تفاعل واكتشف ما يحدث الآن.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenTimelineScreen())),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.bookmarks_outlined),
          title: const Text('Saved Pulse'),
          subtitle: const Text('ارجع للمحتوى الذي حفظته.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenSavedPulseScreen())),
        )),
        ..._items.map((item) => Card(child: ListTile(
          leading: Icon(item.icon),
          title: Text(item.title),
          subtitle: Text(item.subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => item.title == 'Business' ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenBusinessScreen())) : item.title == 'Marketplace' ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenMarketplaceScreen())) : item.title == 'Education' ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenAURENEducationScreen())) : item.title == 'Travel' ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenAURENTravelScreen())) : item.title == 'Entertainment' ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenAURENEntertainmentScreen())) : item.title == 'Creator Studio' ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenAURENCreatorStudioScreen())) : item.title == 'Real Estate' ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenRealEstateScreen())) : item.title == 'Talent Scout' ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenTalentDiscoveryScreen())) : item.title == 'Universal Search' ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenUniversalSearchScreen())) : item.title == 'Trust Graph' ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenTrustGraphScreen())) : item.title == 'Digital Twin' ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenDigitalTwinScreen())) : item.title == 'Future Simulator' ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenFutureSimulatorScreen())) : item.title == 'Random Connect' ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenRandomConnectScreen())) : _open(context, item),
        ))),
        Card(child: ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('Local Intelligence'),
          subtitle: const Text('Business وخدمات وفرص محلية حسب المدينة والدولة.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenLocalIntelligenceScreen())),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.bookmark_outline),
          title: const Text('AUREN Saved'),
          subtitle: const Text('كل المحفوظات من Education وTravel وEntertainment.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenSavedCenterScreen())),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.smart_toy_outlined),
          title: const Text('Agents & Automations'),
          subtitle: const Text('وكلاء، صلاحيات، Wallet، A2A وMarketplace.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenAgentHubScreen())),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.auto_awesome),
          title: const Text('Personal AI'),
          subtitle: const Text('الأهداف، الذاكرة، الفرص والوكلاء.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalAiScreen())),
        )),
      ],
    ),
  );
}

class _MoreItem {
  final String title, subtitle, prompt;
  final IconData icon;
  const _MoreItem(this.title, this.subtitle, this.icon, this.prompt);
}
