import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../search/presentation/global_search_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../education/presentation/education_screen.dart';
import '../../travel/presentation/travel_screen.dart';
import '../../../services/core/auren_core_five_repository.dart';

class AurenNextFiveScreen extends StatelessWidget {
  const AurenNextFiveScreen({super.key});
  static const modules = <_NextModule>[
    _NextModule('Messenger','تواصل + AUREN AI + تنفيذ بإذن المستخدم.',Icons.chat_bubble_outline),
    _NextModule('Universal Search','بحث واحد عبر People وPulse وBusiness وPlaces والفرص.',Icons.search),
    _NextModule('Discover','اكتشاف الأشخاص والأماكن والمبدعين والأعمال والفرص.',Icons.explore_outlined),
    _NextModule('Education','تعلم شخصي مرتبط بالأهداف والمهارات.',Icons.school_outlined),
    _NextModule('Travel','وجهات ورحلات وتجارب مرتبطة بالميزانية والاهتمامات.',Icons.flight_takeoff_outlined),
  ];

  Widget _page(String title) {
    switch (title) {
      case 'Messenger': return const MessengerScreen();
      case 'Universal Search': return const AurenGlobalSearchScreen();
      case 'Discover': return const AurenDiscoverScreen();
      case 'Education': return const AurenAURENEducationScreen();
      case 'Travel': return const AurenAURENTravelScreen();
      default: return const SizedBox.shrink();
    }
  }

  Future<void> _askCore(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen(
        initialPrompt: 'اربط لي Messenger وSearch وDiscover وEducation وTravel في خطة واحدة تناسبني.',
      )));
      return;
    }
    try {
      final snapshot = await AurenCoreFiveRepository().load(uid);
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(
        initialPrompt: snapshot.toPrompt() +
            '\n\nاربط هذا السياق مع Messenger وUniversal Search وDiscover وEducation وTravel، واقترح لي خطوة واحدة عملية.',
      )));
    } catch (_) {
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen(
        initialPrompt: 'اربط لي Messenger وSearch وDiscover وEducation وTravel في خطة واحدة تناسبني.',
      )));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('AUREN Next 5'),
      actions: [
        IconButton(tooltip: 'Core context', onPressed: () => _askCore(context), icon: const Icon(Icons.hub_outlined)),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text('الخمس التالية', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('بعد Core 5، نربط التواصل والبحث والاكتشاف والتعلم والسفر في مسار واحد.'),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: () => _askCore(context), icon: const Icon(Icons.auto_awesome), label: const Text('اربطها لي مع Core 5')),
        const SizedBox(height: 12),
        ...modules.asMap().entries.map((entry) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
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

class _NextModule {
  final String title;
  final String description;
  final IconData icon;
  const _NextModule(this.title, this.description, this.icon);
}
