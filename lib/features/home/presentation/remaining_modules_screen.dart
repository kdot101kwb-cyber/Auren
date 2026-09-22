import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../education/presentation/education_screen.dart';
import '../../travel/presentation/travel_screen.dart';
import '../../entertainment/presentation/entertainment_screen.dart';
import '../../agents/presentation/agent_hub_screen.dart';
import '../../search/presentation/global_search_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import 'next_five_screen.dart';
import 'next_five_systems_screen.dart';

class AurenRemainingModulesScreen extends StatelessWidget {
  const AurenRemainingModulesScreen({super.key});
  static const modules = <_Module>[
    _Module('Messenger','المحادثات، التواصل، وAUREN AI.',Icons.chat_bubble_outline,'messenger'),
    _Module('Universal Search','بحث واحد عبر الأشخاص، المحتوى، الأعمال والفرص.',Icons.search,'search'),
    _Module('Discover','People • Places • Creators • Business • Opportunities.',Icons.explore_outlined,'discover'),
    _Module('Education','التعلم والمسارات والمهارات.',Icons.school_outlined,'education'),
    _Module('Travel','الأماكن والرحلات والتجارب.',Icons.flight_takeoff_outlined,'travel'),
    _Module('Entertainment','Series • Music • Gaming • Live.',Icons.play_circle_outline,'entertainment'),
    _Module('Agents & Automation','الوكلاء، A2A، الصلاحيات، Wallet والتشغيل.',Icons.smart_toy_outlined,'agents'),
    _Module('Files / Browser / VPN','ملفات، تخزين، تصفح واتصال منخفض البيانات.',Icons.folder_outlined,'prompt'),
    _Module('Health / Sports / Fitness','مدرب شخصي، نشاط، رياضة ومتابعة أهداف.',Icons.fitness_center_outlined,'prompt'),
    _Module('Culture / News / Radio','أخبار، ثقافة، بودكاست وراديو ومحتوى محلي.',Icons.public_outlined,'prompt'),
    _Module('Family / Kids / Women','مسارات وتجارب وأدوات عائلية آمنة.',Icons.family_restroom_outlined,'prompt'),
    _Module('Local Intelligence','نقل، طقس، أماكن، طوارئ وخدمات قريبة.',Icons.location_on_outlined,'prompt'),
    _Module('Money / Payments','Wallet، مدفوعات، عملات وفرص مالية.',Icons.account_balance_wallet_outlined,'prompt'),
    _Module('Trust / Safety / Identity','الهوية، السمعة، التقارير، الخصوصية والأمان.',Icons.verified_user_outlined,'prompt'),
    _Module('AUREN World','عوالم وتجارب ومحاكاة مرتبطة بالـAUREN Graph.',Icons.public,'prompt'),
  ];

  Widget _page(_Module m) {
    switch (m.route) {
      case 'messenger': return const MessengerScreen();
      case 'search': return const AurenGlobalSearchScreen();
      case 'discover': return const AurenDiscoverScreen();
      case 'education': return const AurenAURENEducationScreen();
      case 'travel': return const AurenAURENTravelScreen();
      case 'entertainment': return const AurenAURENEntertainmentScreen();
      case 'agents': return const AurenAgentHubScreen();
      default: return MessengerScreen(initialPrompt:'افتح لي وحدة '+m.title+' في AUREN. اشرح لي ما المتاح حاليًا، وما الخطوة العملية التالية، واربطها بالوحدات الأخرى بدون تكرار.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN — Remaining Modules')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16,12,16,28),
      children: [
        Text('باقي منظومة AUREN',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.bold)),
        const SizedBox(height:6),
        const Text('الوحدات الأساسية المتبقية مجمعة هنا حتى نكملها فوق الـCore 5 بدون إعادة بناء ما تم إنجازه.'),
        const SizedBox(height:16),
        Card(child: ListTile(
          leading: const Icon(Icons.rocket_launch_outlined),
          title: const Text('AUREN Next 5 Systems'),
          subtitle: const Text('Entertainment • Agents • Local Intelligence • Money • Trust'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenNextFiveSystemsScreen())),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.route_outlined),
          title: const Text('AUREN Next 5'),
          subtitle: const Text('Messenger • Search • Discover • Education • Travel'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenNextFiveScreen())),
        )),
        ...modules.asMap().entries.map((e)=>Card(
          margin:const EdgeInsets.only(bottom:10),
          child:ListTile(
            leading:CircleAvatar(child:Text((e.key+1).toString())),
            title:Text(e.value.title,style:const TextStyle(fontWeight:FontWeight.bold)),
            subtitle:Text(e.value.description),
            trailing:const Icon(Icons.chevron_right),
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>_page(e.value))),
          ),
        )),
      ],
    ),
  );
}
class _Module {
  final String title,description,route;
  final IconData icon;
  const _Module(this.title,this.description,this.icon,this.route);
}
