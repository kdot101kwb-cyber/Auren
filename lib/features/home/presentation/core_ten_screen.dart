import 'package:flutter/material.dart';
import '../../personal_ai/presentation/personal_ai_screen.dart';
import '../../social/presentation/timeline_screen.dart';
import '../../business/presentation/business_screen.dart';
import '../../marketplace/presentation/marketplace_screen.dart';
import '../../creator/presentation/creator_screen.dart';
import '../../education/presentation/education_screen.dart';
import '../../travel/presentation/travel_screen.dart';
import '../../entertainment/presentation/entertainment_screen.dart';
import '../../agents/presentation/agent_hub_screen.dart';
import '../../search/presentation/global_search_screen.dart';

class AurenCoreTenScreen extends StatelessWidget {
  const AurenCoreTenScreen({super.key});

  static const modules = <_Module>[
    _Module('Personal AI','أهداف، ذاكرة، فرص وتنفيذ.',Icons.auto_awesome),
    _Module('Social / Pulse','نشر وتفاعل واكتشاف.',Icons.dynamic_feed_outlined),
    _Module('Business','شركات ومتاجر وخدمات.',Icons.storefront_outlined),
    _Module('Marketplace','منتجات، خدمات وطلبات.',Icons.shopping_bag_outlined),
    _Module('Creator Studio','إنشاء ونشر وتطوير المحتوى.',Icons.video_camera_back_outlined),
    _Module('Education','تعلم ومهارات ومسارات عملية.',Icons.school_outlined),
    _Module('Travel','وجهات ورحلات وتجارب.',Icons.flight_takeoff_outlined),
    _Module('Entertainment','Series، Anime، Podcasts، Books.',Icons.play_circle_outline),
    _Module('Agents & Automations','وكلاء، صلاحيات، A2A وWallet.',Icons.smart_toy_outlined),
    _Module('Universal Search','بحث شامل + Ask AUREN + نتائج قابلة للتنفيذ.',Icons.search),
  ];

  Widget _page(String title) {
    switch(title) {
      case 'Personal AI': return const PersonalAiScreen();
      case 'Social / Pulse': return const AurenTimelineScreen();
      case 'Business': return const AurenBusinessScreen();
      case 'Marketplace': return const AurenMarketplaceScreen();
      case 'Creator Studio': return const AurenAURENCreatorStudioScreen();
      case 'Education': return const AurenAURENEducationScreen();
      case 'Travel': return const AurenAURENTravelScreen();
      case 'Entertainment': return const AurenAURENEntertainmentScreen();
      case 'Agents & Automations': return const AurenAgentHubScreen();
      case 'Universal Search': return const AurenGlobalSearchScreen();
      default: return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN Core 10')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16,12,16,28),
      children: [
        Text('أول 10 وحدات',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.bold)),
        const SizedBox(height:6),
        const Text('عشرة أنظمة أساسية متصلة داخل تجربة AUREN واحدة — بدون إنشاء نسخ مكررة.'),
        const SizedBox(height:18),
        ...modules.asMap().entries.map((e)=>Card(
          margin:const EdgeInsets.only(bottom:10),
          child:ListTile(
            leading:CircleAvatar(child:Text('${e.key+1}')),
            title:Row(children:[Icon(e.value.icon,size:20),const SizedBox(width:8),Expanded(child:Text(e.value.title,style:const TextStyle(fontWeight:FontWeight.bold)))]),
            subtitle:Padding(padding:const EdgeInsets.only(top:4),child:Text(e.value.description)),
            trailing:const Icon(Icons.chevron_right),
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>_page(e.value.title))),
          ),
        )),
      ],
    ),
  );
}

class _Module {
  final String title;
  final String description;
  final IconData icon;
  const _Module(this.title,this.description,this.icon);
}
