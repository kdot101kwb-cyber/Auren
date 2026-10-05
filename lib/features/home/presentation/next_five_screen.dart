import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../search/presentation/global_search_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../education/presentation/education_screen.dart';
import '../../travel/presentation/travel_screen.dart';
import '../../../services/core/auren_core_five_repository.dart';
import '../../../services/core/auren_next_five_repository.dart';

class AurenNextFiveScreen extends StatefulWidget {
  const AurenNextFiveScreen({super.key});
  @override State<AurenNextFiveScreen> createState() => _AurenNextFiveScreenState();
}

class _AurenNextFiveScreenState extends State<AurenNextFiveScreen> {
  late Future<AurenNextFiveSnapshot> _snapshot;
  @override void initState() { super.initState(); _load(); }
  void _load() { final uid = FirebaseAuth.instance.currentUser?.uid; _snapshot = uid == null ? Future.value(const AurenNextFiveSnapshot(learningTracks:0,trips:0,hasAiConversation:false,completedLessons:null,tripNames:[])) : AurenNextFiveRepository().load(uid); }
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
        IconButton(tooltip: 'Refresh', onPressed: () => setState(_load), icon: const Icon(Icons.refresh)),
        IconButton(tooltip: 'Core context', onPressed: () => _askCore(context), icon: const Icon(Icons.hub_outlined)),
      ],
    ),
    body: FutureBuilder<AurenNextFiveSnapshot>(
      future: _snapshot,
      builder: (context, state) {
        if (state.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (state.hasError || state.data == null) return Center(child: OutlinedButton.icon(onPressed: () => setState(_load), icon: const Icon(Icons.refresh), label: const Text('حاول مرة أخرى')));
        final s = state.data!;
        return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text('الخمس التالية', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('بعد Core 5، نربط التواصل والبحث والاكتشاف والتعلم والسفر في مسار واحد.'),
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.hub_outlined), const SizedBox(width: 8), const Expanded(child: Text('Next 5 Context', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), Text((s.learningTracks + s.trips).toString())]), const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: [Chip(avatar: const Icon(Icons.chat_bubble_outline, size: 18), label: Text(s.hasAiConversation ? 'AI متصل' : 'AI جديد')), Chip(avatar: const Icon(Icons.school_outlined, size: 18), label: Text(s.learningTracks.toString() + ' Learning')), Chip(avatar: const Icon(Icons.flight_takeoff_outlined, size: 18), label: Text(s.trips.toString() + ' Trips')), if (s.completedLessons != null) Chip(label: Text(s.completedLessons.toString() + ' lessons'))]), const SizedBox(height: 10), Text(s.nextMove, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 10), FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: s.toPrompt()))), icon: const Icon(Icons.auto_awesome), label: const Text('اسأل AUREN عن الربط التالي'))]))),
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
        );
      },
    ),
  );
}

class _NextModule {
  final String title;
  final String description;
  final IconData icon;
  const _NextModule(this.title, this.description, this.icon);
}
