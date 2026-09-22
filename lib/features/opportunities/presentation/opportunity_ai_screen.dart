import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenOpportunityAiScreen extends StatelessWidget {
  const AurenOpportunityAiScreen({super.key});

  static const actions = [
    ('Opportunity Radar','ابحث عن فرص تناسب أهدافي ومهاراتي الآن.'),
    ('Career Path','ابنِ لي مسارًا مهنيًا عمليًا من وضعي الحالي.'),
    ('Skill Gap','حلّل المهارات التي أحتاجها للوصول لهدفي.'),
    ('Application Coach','ساعدني أجهز CV ورسالة تقديم وخطة متابعة.'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Opportunity & Career AI')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Opportunity Engine', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('AUREN يربط الهدف بالمهارة والفرصة والخطوة التالية.'),
        const SizedBox(height: 18),
        ...actions.map((a) => Card(
          child: ListTile(
            leading: const Icon(Icons.work_outline),
            title: Text(a.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(a.$2),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: a.$2)),
            ),
          ),
        )),
      ],
    ),
  );
}
