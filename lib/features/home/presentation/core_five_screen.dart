import 'package:flutter/material.dart';

import '../../personal_ai/presentation/personal_ai_screen.dart';
import '../../social/presentation/timeline_screen.dart';
import '../../business/presentation/business_screen.dart';
import '../../marketplace/presentation/marketplace_screen.dart';
import '../../creator/presentation/creator_screen.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Core 5')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text('أول 5 وحدات أساسية',style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('هذه هي الطبقة التي تجمع الذكاء الشخصي، التواصل، الأعمال، التجارة وصناعة المحتوى في تجربة واحدة.'),
          const SizedBox(height: 18),
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
}

class _CoreModule {
  final String title;
  final String description;
  final IconData icon;
  const _CoreModule(this.title, this.description, this.icon);
}
