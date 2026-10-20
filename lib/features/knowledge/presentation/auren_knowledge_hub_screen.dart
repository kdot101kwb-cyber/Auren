import 'package:flutter/material.dart';

import '../../messenger/presentation/messenger_screen.dart';

/// A lightweight knowledge navigator that reuses AUREN's existing assistant.
class AurenKnowledgeHubScreen extends StatelessWidget {
  const AurenKnowledgeHubScreen({super.key});

  static const _domains = <_KnowledgeDomain>[
    _KnowledgeDomain(
      'Science & Technology',
      'مفاهيم علمية وتقنية مع شرح تدريجي.',
      Icons.science_outlined,
      'اشرح لي موضوعاً في العلوم أو التقنية تدريجياً، وميّز بين المعرفة الراسخة والفرضيات.',
    ),
    _KnowledgeDomain(
      'Business & Economics',
      'الأسواق والصناعة والتجارة والاقتصاد.',
      Icons.query_stats_outlined,
      'ساعدني أدرس موضوعاً اقتصادياً أو تجارياً، مع توضيح الافتراضات والبيانات التي تحتاج إلى مصادر حديثة.',
    ),
    _KnowledgeDomain(
      'History & Society',
      'التاريخ والمجتمعات والسياق الثقافي.',
      Icons.account_balance_outlined,
      'اشرح لي موضوعاً تاريخياً أو اجتماعياً مع سياقه، وميّز بين الوقائع المتفق عليها والتفسيرات المختلفة.',
    ),
    _KnowledgeDomain(
      'Practical Skills',
      'معرفة عملية تتحول إلى خطوات قابلة للتطبيق.',
      Icons.build_outlined,
      'حوّل الموضوع الذي أختاره إلى مسار تعلم عملي بمراحل وتمارين ومؤشرات تقدم.',
    ),
    _KnowledgeDomain(
      'Sudan & Africa',
      'معرفة مرتبطة بالسودان وأفريقيا وأسواقهما.',
      Icons.public_outlined,
      'ساعدني أتعلم عن السودان وأفريقيا في الموضوع الذي أحدده، مع مراعاة اختلاف البلدان وتاريخ المعلومات.',
    ),
  ];

  void _open(BuildContext context, _KnowledgeDomain domain) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessengerScreen(
          initialPrompt: '${domain.prompt}\n\nاسألني عن الموضوع المحدد، ثم رتّب الإجابة إلى شرح ومصطلحات وأسئلة للمراجعة.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Knowledge Hub')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'المعرفة التي تقود إلى الفهم',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اختر مجالاً لتبدأ مسار تعلم موجهاً. هذه الواجهة تستخدم مساعد AUREN الموجود؛ '
            'هي ليست بعد قاعدة معرفة موثقة أو مخزناً دائماً للملاحظات.',
          ),
          const SizedBox(height: 16),
          ..._domains.map(
            (domain) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(child: Icon(domain.icon)),
                  title: Text(
                    domain.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(domain.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, domain),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeDomain {
  final String title;
  final String subtitle;
  final IconData icon;
  final String prompt;

  const _KnowledgeDomain(this.title, this.subtitle, this.icon, this.prompt);
}
