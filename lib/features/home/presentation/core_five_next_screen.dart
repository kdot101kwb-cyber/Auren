import 'package:flutter/material.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../education/presentation/education_screen.dart';
import '../../travel/presentation/travel_screen.dart';
import '../../entertainment/presentation/entertainment_screen.dart';

class AurenCoreFiveNextScreen extends StatelessWidget {
  const AurenCoreFiveNextScreen({super.key});

  static const modules = <_Module>[
    _Module('Discover', 'اكتشاف الأشخاص والأماكن والمحتوى والفرص.', Icons.explore_outlined),
    _Module('Messenger', 'التواصل مع الناس وAUREN AI مع الأمان والموافقات.', Icons.chat_bubble_outline),
    _Module('Education', 'تعلم شخصي مرتبط بالأهداف والمهارات.', Icons.school_outlined),
    _Module('Travel', 'أماكن ورحلات وتجارب مع التخطيط الذكي.', Icons.flight_takeoff_outlined),
    _Module('Entertainment', 'Global Series وAnime وPodcasts وBooks وAUREN World.', Icons.play_circle_outline),
  ];

  Widget _page(String title) {
    switch (title) {
      case 'Discover': return const AurenDiscoverScreen();
      case 'Messenger': return const MessengerScreen();
      case 'Education': return const AurenAURENEducationScreen();
      case 'Travel': return const AurenAURENTravelScreen();
      case 'Entertainment': return const AurenAURENEntertainmentScreen();
      default: return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN Core 5 — Next')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text('الوحدات 6–10', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('دفعة واحدة: اكتشاف، تواصل، تعلم، سفر وترفيه — مرتبطة مباشرة بالأنظمة الحالية.'),
        const SizedBox(height: 18),
        ...modules.asMap().entries.map((entry) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(child: Text('${entry.key + 6}')),
            title: Row(children: [
              Icon(entry.value.icon, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(entry.value.title, style: const TextStyle(fontWeight: FontWeight.bold))),
            ]),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(entry.value.description),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _page(entry.value.title))),
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
  const _Module(this.title, this.description, this.icon);
}
