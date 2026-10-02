import 'package:flutter/material.dart';

import '../../messenger/presentation/messenger_screen.dart';

class AurenCultureNewsScreen extends StatelessWidget {
  const AurenCultureNewsScreen({super.key});

  void _ask(BuildContext context, String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)),
    );
  }

  static const _sections = <_CultureSection>[
    _CultureSection('Global News', 'أخبار العالم مع تلخيص وسياق من AUREN', Icons.public_outlined, 'اعرض لي أهم أخبار العالم الآن، مع مصادر وسياق مختصر وميّز بين الخبر والتحليل.'),
    _CultureSection('Culture', 'ثقافات الشعوب، اللغات، الفنون والعادات', Icons.palette_outlined, 'اكتشف ثقافات العالم: فنون، لغات، عادات، تاريخ وحكايات محلية، مع احترام اختلاف المصادر.'),
    _CultureSection('Heritage', 'تراث ومواقع ثقافية حول العالم', Icons.account_balance_outlined, 'اكتشف مواقع التراث والثقافة المهمة حول العالم، ولماذا هي مهمة وكيف أتعلم عنها.'),
    _CultureSection('AI Briefing', 'ملخص ثقافي وإخباري شخصي', Icons.auto_awesome_outlined, 'أنشئ لي موجزًا يوميًا شخصيًا يجمع الأخبار والثقافة والمعرفة، مع مصادر وسبب اختيار كل موضوع.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Culture & News')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text('AUREN Culture & News', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('أخبار العالم + الثقافة + التراث في مساحة واحدة، مع AI يساعدك تفهم المحتوى دون تكرار أنظمة Education وTravel وLibrary.'),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
              title: const Text('موجزي الآن'),
              subtitle: const Text('اطلب من AUREN ملخصًا شخصيًا للأخبار والثقافة والمعرفة.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _ask(context, 'أنشئ لي موجزًا الآن عن أهم الأخبار والثقافة والمعرفة التي تستحق اهتمامي اليوم، مع مصادر وسبب اختيار كل موضوع.'),
            ),
          ),
          const SizedBox(height: 14),
          ..._sections.map((section) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(child: Icon(section.icon)),
                title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(section.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _ask(context, section.prompt),
              ),
            ),
          )),
          const SizedBox(height: 4),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('ملاحظة: عند عرض الأخبار أو المعلومات المتغيرة، اطلب من AUREN إظهار المصادر والتاريخ حتى تقدر تراجع المعلومة بنفسك.'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CultureSection {
  final String title;
  final String subtitle;
  final IconData icon;
  final String prompt;
  const _CultureSection(this.title, this.subtitle, this.icon, this.prompt);
}