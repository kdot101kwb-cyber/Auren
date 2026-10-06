import 'package:flutter/material.dart';

/// AUREN Idea Lab: a multi-agent creative engine that intentionally
/// challenges normal answers instead of behaving like a generic chatbot.
class AurenIdeaLab {
  static const modes = <String>[
    'Mad Inventor',
    'Fusion AI',
    'Contrarian AI',
    'Future AI',
    'Experiment AI',
    'Wildcard AI',
    'Founder Challenger',
  ];

  static List<String> generate(String topic) {
    final t = topic.trim().isEmpty ? 'AUREN' : topic.trim();
    return [
      'Mad Inventor: ماذا لو قلبنا طريقة $t بالكامل بدل تحسينها بالطريقة المعتادة؟',
      'Fusion AI: ادمج $t مع Gaming + Social + AI في تجربة واحدة لا تبدو كمنتج تقليدي.',
      'Contrarian AI: افعل عكس الافتراض الأساسي في $t، ثم ابحث عن فائدة غير متوقعة.',
      'Future AI: تخيل $t في 2036، ثم استخرج منه ميزة يمكن بناؤها الآن.',
      'Experiment AI: حوّل أفضل فكرة إلى تجربة صغيرة يمكن اختبارها خلال أسبوع.',
      'Wildcard AI: فكرة لا علاقة مباشرة لها بالطلب، لكن يمكن أن تفتح سوقًا أو استخدامًا جديدًا.',
      'Founder Challenger: ما الجزء الضعيف في فكرة $t؟ وما الفكرة الجريئة التي قد تجعلها أقوى 10 مرات؟',
    ];
  }
}

class AurenIdeaLabScreen extends StatefulWidget {
  const AurenIdeaLabScreen({super.key});

  @override
  State<AurenIdeaLabScreen> createState() => _AurenIdeaLabScreenState();
}

class _AurenIdeaLabScreenState extends State<AurenIdeaLabScreen> {
  final _controller = TextEditingController();
  List<String> _ideas = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ignite() {
    setState(() => _ideas = AurenIdeaLab.generate(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Idea Lab'),
        actions: [
          IconButton(
            tooltip: 'Generate',
            onPressed: _ignite,
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology_alt_outlined),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Crazy Ideas / Idea Fusion',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'سبعة عقول إبداعية تتنافس: تخترع، تدمج، تعارض، تتخيل المستقبل، '
                    'تجرب، تفاجئك، وتتحدى الفكرة بدل الموافقة عليها تلقائيًا.',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _ignite(),
                    decoration: InputDecoration(
                      hintText: 'مثلاً: فكرة جديدة للتصوير',
                      prefixIcon: const Icon(Icons.lightbulb_outline),
                      suffixIcon: IconButton(
                        onPressed: _ignite,
                        icon: const Icon(Icons.bolt),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...AurenIdeaLab.modes.map(
            (mode) => Chip(
              avatar: const Icon(Icons.auto_awesome, size: 18),
              label: Text(mode),
            ),
          ),
          if (_ideas.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'مختبر الأفكار',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ..._ideas.asMap().entries.map(
              (entry) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${entry.key + 1}')),
                  title: Text(entry.value),
                  trailing: IconButton(
                    tooltip: 'Copy idea',
                    onPressed: () {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('الفكرة جاهزة للنقل إلى AUREN AI.')),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
