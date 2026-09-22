import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../entertainment/presentation/entertainment_screen.dart';
import '../../agents/presentation/agent_hub_screen.dart';

class AurenNextFiveSystemsScreen extends StatelessWidget {
  const AurenNextFiveSystemsScreen({super.key});
  static const modules = <_Module>[
    _Module('Entertainment','Series • Music • Gaming • Live والمحتوى العالمي.',Icons.play_circle_outline,'entertainment'),
    _Module('Agents & Automation','وكلاء، A2A، صلاحيات، Wallet وتشغيل مهام بإذن المستخدم.',Icons.smart_toy_outlined,'agents'),
    _Module('Local Intelligence','خدمات محلية، نقل، أماكن، طوارئ ومعلومات مرتبطة بالسياق.',Icons.location_on_outlined,'prompt'),
    _Module('Money / Payments','Wallet، العملات، الدفع، التجارة والعمليات المالية.',Icons.account_balance_wallet_outlined,'prompt'),
    _Module('Trust / Safety / Identity','هوية، ثقة، سمعة، تقارير، خصوصية وأمان.',Icons.verified_user_outlined,'prompt'),
  ];

  Widget _page(_Module m) {
    switch (m.route) {
      case 'entertainment': return const AurenAURENEntertainmentScreen();
      case 'agents': return const AurenAgentHubScreen();
      default:
        return MessengerScreen(initialPrompt:
          'افتح لي وحدة ${m.title} في AUREN. اعرض الموجود فعليًا، وما الناقص، ثم اقترح تنفيذ الخطوة العملية التالية مع ربطها بالوحدات الموجودة بدون تكرار.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN Next 5 Systems')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text('الخمس التالية', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('نواصل بناء المنظومة بعد Core 5 وNext 5، بدون إعادة الوحدات السابقة.'),
        const SizedBox(height: 18),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          const CircleAvatar(child: Icon(Icons.rocket_launch_outlined)),
          const SizedBox(width: 12),
          const Expanded(child: Text('هذه الدفعة تربط الترفيه والوكلاء والذكاء المحلي والمال والثقة.', style: TextStyle(fontWeight: FontWeight.w600))),
        ]))),
        const SizedBox(height: 12),
        ...modules.asMap().entries.map((e) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(child: Text('${e.key + 1}')),
            title: Row(children: [Icon(e.value.icon, size: 20), const SizedBox(width: 8), Expanded(child: Text(e.value.title, style: const TextStyle(fontWeight: FontWeight.bold)))]),
            subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(e.value.description)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _page(e.value))),
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
  final String route;
  const _Module(this.title, this.description, this.icon, this.route);
}
