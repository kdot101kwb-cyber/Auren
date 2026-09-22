import 'package:flutter/material.dart';
import '../../personal_ai/presentation/personal_ai_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../social/presentation/timeline_screen.dart';
import '../../business/presentation/business_screen.dart';
import '../../marketplace/presentation/marketplace_screen.dart';
import '../../creator/presentation/creator_screen.dart';
import '../../education/presentation/education_screen.dart';
import '../../travel/presentation/travel_screen.dart';
import '../../entertainment/presentation/entertainment_screen.dart';
import '../../agents/presentation/agent_hub_screen.dart';

class AurenSystems47Screen extends StatelessWidget {
  const AurenSystems47Screen({super.key});
  static const systems = <_System>[
    _System(1,'AUREN AI','الذكاء المركزي',Icons.auto_awesome), _System(2,'AUREN Life Engine','إدارة الحياة والأهداف',Icons.track_changes),
    _System(3,'AUREN World','العالم والتجارب الرقمية',Icons.public), _System(4,'AUREN Travel','السفر والثقافة',Icons.flight_takeoff),
    _System(5,'AUREN Mobility','التنقل والخدمات',Icons.directions_car), _System(6,'AUREN Maps','الخرائط والمواقع',Icons.map_outlined),
    _System(7,'AUREN Connect / Messenger','التواصل والمراسلة',Icons.chat_bubble_outline), _System(8,'AUREN Communities','المجتمعات',Icons.groups_outlined),
    _System(9,'AUREN Social / Timeline','الاجتماعي وPulse',Icons.dynamic_feed_outlined), _System(10,'AUREN Profile','الهوية والملف الشخصي',Icons.person_outline),
    _System(11,'AUREN Creator / Studio','صناعة المحتوى',Icons.video_camera_back_outlined), _System(12,'AUREN Stars / Economy','النجوم والاقتصاد الداخلي',Icons.stars_outlined),
    _System(13,'AUREN Marketplace','التجارة والشراء والبيع',Icons.shopping_bag_outlined), _System(14,'AUREN Global Trade','التجارة الدولية',Icons.public),
    _System(15,'AUREN Business','الشركات والخدمات',Icons.storefront_outlined), _System(16,'AUREN Growth','النمو والوصول',Icons.trending_up),
    _System(17,'AUREN Wallet / Payments','المحفظة والمدفوعات',Icons.account_balance_wallet_outlined), _System(18,'AUREN Entertainment','الترفيه والمحتوى',Icons.play_circle_outline),
    _System(19,'AUREN Music','الموسيقى والصوت',Icons.music_note), _System(20,'AUREN Sports','الرياضة',Icons.sports_soccer),
    _System(21,'AUREN Games','الألعاب',Icons.sports_esports), _System(22,'AUREN Education / Campus','التعليم',Icons.school_outlined),
    _System(23,'AUREN Skills / Skill Coach','المهارات والتدريب',Icons.psychology_outlined), _System(24,'AUREN Talent','المواهب',Icons.workspace_premium_outlined),
    _System(25,'AUREN Events','الفعاليات',Icons.event_outlined), _System(26,'AUREN Arts & Culture','الفنون والثقافة',Icons.palette_outlined),
    _System(27,'AUREN Fashion','الموضة',Icons.checkroom_outlined), _System(28,'AUREN Tech & Electronics','التقنية والإلكترونيات',Icons.devices_other),
    _System(29,'AUREN App Store / App Marketplace','تطبيقات وخدمات رقمية',Icons.apps_outlined), _System(30,'AUREN App Factory','مصنع التطبيقات',Icons.factory_outlined),
    _System(31,'AUREN Files / Cloud','الملفات والسحابة',Icons.cloud_outlined), _System(32,'AUREN Pulse / Discussions','النقاشات والتفاعل',Icons.forum_outlined),
    _System(33,'AUREN Live Planet','البث والعالم الحي',Icons.live_tv_outlined), _System(34,'AUREN Access','الوصول والصلاحيات',Icons.admin_panel_settings_outlined),
    _System(35,'AUREN Security / Trust','الأمان والثقة',Icons.security_outlined), _System(36,'AUREN Discover','الاكتشاف',Icons.explore_outlined),
    _System(37,'AUREN Analytics / Intelligence','التحليلات والذكاء',Icons.analytics_outlined), _System(38,'AUREN Ads / Campaign','الإعلانات والحملات',Icons.campaign_outlined),
    _System(39,'AUREN Partnerships','الشراكات',Icons.handshake_outlined), _System(40,'AUREN Impact','الأثر والمبادرات',Icons.volunteer_activism_outlined),
    _System(41,'AUREN App Factory Extensions','توسعة مصنع التطبيقات',Icons.build_circle_outlined), _System(42,'AUREN Files / Cloud Extensions','توسعة الملفات والسحابة',Icons.folder_special_outlined),
    _System(43,'AUREN Pulse Extensions','توسعة Pulse',Icons.bolt_outlined), _System(44,'AUREN Live Planet Extensions','توسعة Live Planet',Icons.language_outlined),
    _System(45,'AUREN Events Extensions','توسعة الفعاليات',Icons.event_available_outlined), _System(46,'AUREN Partnerships Extensions','توسعة الشراكات',Icons.handshake),
    _System(47,'AUREN Impact Extensions','توسعة الأثر',Icons.public_outlined),
  ];
  Widget _open(BuildContext context, _System s) {
    switch(s.id) {
      case 1: case 2: return const PersonalAiScreen();
      case 7: return const MessengerScreen();
      case 9: case 32: return const AurenTimelineScreen();
      case 11: return const AurenAURENCreatorStudioScreen();
      case 13: return const AurenMarketplaceScreen();
      case 15: return const AurenBusinessScreen();
      case 18: return const AurenAURENEntertainmentScreen();
      case 22: return const AurenAURENEducationScreen();
      case 4: return const AurenAURENTravelScreen();
      case 24: return const AurenAgentHubScreen();
      default: return MessengerScreen(initialPrompt:'افتح نظام '+s.title+' في AUREN واشرح لي ما أستطيع فعله الآن.');
    }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN — 47 Systems')),
    body: ListView.builder(
      padding: const EdgeInsets.all(12), itemCount: systems.length,
      itemBuilder: (context,index) {
        final s=systems[index];
        return Card(child: ListTile(
          leading: CircleAvatar(child: Text(s.id.toString())),
          title: Text(s.title,style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(s.description), trailing: const Icon(Icons.chevron_right),
          onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>_open(context,s))),
        ));
      },
    ),
  );
}
class _System {
  final int id; final String title; final String description; final IconData icon;
  const _System(this.id,this.title,this.description,this.icon);
}
