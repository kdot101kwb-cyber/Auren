import 'package:flutter/material.dart';
import 'kids_parent_center_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenKidsScreen extends StatefulWidget {
  const AurenKidsScreen({super.key});
  @override State<AurenKidsScreen> createState() => _AurenKidsScreenState();
}

class _AurenKidsScreenState extends State<AurenKidsScreen> {
  int ageBand = 6;
  final activities = const <Map<String, Object>>[
    {'title':'Learn & Explore','subtitle':'تعلم ممتع ومناسب للعمر','icon':Icons.school_outlined},
    {'title':'Creative Studio','subtitle':'رسم، قصص ومشاريع إبداعية','icon':Icons.palette_outlined},
    {'title':'Games & Challenges','subtitle':'ألعاب وتحديات تعليمية بدون رهانات','icon':Icons.extension_outlined},
    {'title':'World Discovery','subtitle':'علوم، ثقافات ولغات حول العالم','icon':Icons.public_outlined},
  ];

  void _openTutor(BuildContext context, String prompt) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Kids')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('مساحة آمنة للتعلّم والنمو', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('محتوى تعليمي وإبداعي مصمم حسب العمر، مع تجربة منفصلة عن اجتماعات ومراسلات البالغين.'),
                const SizedBox(height: 16),
                Text('الفئة العمرية', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [6, 9, 13].map((age) => ChoiceChip(label: Text(age == 13 ? '13–17' : '$age–${age + 2}'), selected: ageBand == age, onSelected: (_) => setState(() => ageBand = age))).toList()),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(child: ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('AI Learning Coach'), subtitle: Text('خطة تعلم يومية للفئة $ageBand+ مع أنشطة مناسبة للعمر.'), trailing: const Icon(Icons.chevron_right), onTap: () => _openTutor(context, 'أنشئ خطة تعلم آمنة ومناسبة لعمر طفل في الفئة $ageBand+، مع أهداف يومية وأنشطة قصيرة وتعليم بالتجربة.'))),
          const SizedBox(height: 12),
          Text('استكشف', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...activities.map((item) => Card(child: ListTile(leading: Icon(item['icon'] as IconData), title: Text(item['title'] as String), subtitle: Text(item['subtitle'] as String), trailing: const Icon(Icons.chevron_right), onTap: () => _openTutor(context, 'اقترح أنشطة آمنة ومناسبة للأطفال في ${item['title']} للفئة العمرية $ageBand+. اجعلها تعليمية، قصيرة، وإبداعية.')))),
          const SizedBox(height: 12),
          Card(
            child: Column(children: [
              ListTile(leading: const Icon(Icons.family_restroom_outlined), title: const Text('Parent Center'), subtitle: const Text('إعدادات الأسرة، الخصوصية ومتابعة التعلم تكون بيد ولي الأمر.'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenKidsParentCenterScreen()))),
              const Divider(height: 1),
              ListTile(leading: const Icon(Icons.lock_outline), title: const Text('Safety first'), subtitle: const Text('لا توجد مراسلة عامة للأطفال ضمن مساحة Kids.'), trailing: const Icon(Icons.verified_outlined)),
            ]),
          ),
        ],
      ),
    );
  }
}