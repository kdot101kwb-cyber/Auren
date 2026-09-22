import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/core/auren_core_five_repository.dart';
import '../../personal_ai/presentation/personal_ai_screen.dart';
import '../../social/presentation/timeline_screen.dart';
import '../../business/presentation/business_screen.dart';
import '../../marketplace/presentation/marketplace_screen.dart';
import '../../creator/presentation/creator_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';

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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AUREN Core 5')),
        body: const Center(child: Text('سجّل الدخول لاستخدام Core 5.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Core 5')),
      body: FutureBuilder<AurenCoreFiveSnapshot>(
        future: AurenCoreFiveRepository().load(uid),
        builder: (context, snapshot) {
          final data = snapshot.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Text('أول 5 وحدات أساسية',style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('طبقة واحدة تربط الذكاء الشخصي، التواصل، الأعمال، التجارة وصناعة المحتوى.'),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(),
              if (data != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _stat('Goals', data.activeGoals),
                        _stat('Pulse', data.posts),
                        _stat('Business', data.businesses),
                        _stat('Products', data.products),
                        _stat('Drafts', data.creatorDrafts),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.trending_up),
                    title: const Text('Next move'),
                    subtitle: Text(data.nextMove),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
                    title: const Text('AUREN Core 5 AI'),
                    subtitle: const Text('اربط بيانات الوحدات الخمس واقترح لي خطوة واحدة قابلة للتنفيذ.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessengerScreen(
                          initialPrompt: data.toPrompt(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (snapshot.hasError)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('بعض بيانات الوحدات غير متاحة الآن'),
                    subtitle: const Text('يمكنك فتح الوحدات مباشرة والاستمرار بشكل طبيعي.'),
                  ),
                ),
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
          );
        },
      ),
    );
  }

  static Widget _stat(String label, int value) => Chip(
    avatar: const Icon(Icons.circle, size: 10),
    label: Text('$label: $value'),
  );
}

class _CoreModule {
  final String title;
  final String description;
  final IconData icon;
  const _CoreModule(this.title, this.description, this.icon);
}
