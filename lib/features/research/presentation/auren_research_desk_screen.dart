import 'package:flutter/material.dart';

import '../../messenger/presentation/messenger_screen.dart';
import '../../knowledge/presentation/auren_knowledge_hub_screen.dart';
import '../../language_bridge/presentation/auren_language_bridge_screen.dart';

/// Research workspace that routes each task to AUREN's existing assistant.
class AurenResearchDeskScreen extends StatefulWidget {
  const AurenResearchDeskScreen({super.key});

  @override
  State<AurenResearchDeskScreen> createState() => _AurenResearchDeskScreenState();
}

class _AurenResearchDeskScreenState extends State<AurenResearchDeskScreen> {
  final TextEditingController _topicController = TextEditingController();

  static const _tools = <_ResearchTool>[
    _ResearchTool(
      title: 'Research Brief',
      subtitle: 'حوّل السؤال إلى خطة بحث واضحة وملخص منظم.',
      icon: Icons.manage_search_outlined,
      prompt: 'أنشئ خطة بحث منظمة للموضوع التالي. وضّح الأسئلة الفرعية، والنطاق، وما يحتاج إلى تحقق، ولا تخترع مصادر:',
    ),
    _ResearchTool(
      title: 'Compare Sources',
      subtitle: 'قارن الأدلة والاختلافات بين المصادر.',
      icon: Icons.compare_arrows_outlined,
      prompt: 'قارن المصادر المتاحة حول الموضوع التالي. افصل الحقائق عن الآراء، واذكر نقاط الاتفاق والاختلاف وحدود الأدلة:',
    ),
    _ResearchTool(
      title: 'Claim Check',
      subtitle: 'افحص الادعاءات وحدد ما يمكن إثباته.',
      icon: Icons.fact_check_outlined,
      prompt: 'ساعدني في التحقق من الادعاء التالي. صنّف كل جزء إلى مؤكد أو غير محسوم أو غير مدعوم، واطلب مصادر قابلة للمراجعة ولا تدّعِ التحقق إن لم تتوفر مصادر:',
    ),
    _ResearchTool(
      title: 'Language Bridge',
      subtitle: 'افهم المصطلحات والسياق بين اللغات.',
      icon: Icons.translate_outlined,
      prompt: 'اشرح وترجم الموضوع التالي بلغة واضحة، واحتفظ بالمصطلحات المهمة بلغتها الأصلية، ونبّه إلى أي غموض أو اختلاف ثقافي:',
    ),
    _ResearchTool(
      title: 'Citation Planner',
      subtitle: 'نظّم المراجع والاقتباسات المطلوبة للبحث.',
      icon: Icons.format_quote_outlined,
      prompt: 'أنشئ خطة للمراجع والاقتباسات المطلوبة للموضوع التالي. لا تخترع أسماء كتب أو روابط أو بيانات نشر؛ ميّز بين المراجع التي تم العثور عليها وتلك التي ما زالت مطلوبة:',
    ),
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _openTool(_ResearchTool tool) {
    final topic = _topicController.text.trim();
    final prompt = topic.isEmpty
        ? '${tool.prompt}\n\nابدأ بسؤالي عن الموضوع والنطاق المطلوب.'
        : '${tool.prompt}\n\nالموضوع: $topic';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessengerScreen(initialPrompt: prompt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Research Desk')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'من السؤال إلى معرفة قابلة للمراجعة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'مساحة لتنظيم البحث، مقارنة الأدلة، فحص الادعاءات، وفهم المصطلحات. '
            'تأكد دائماً من فتح المصادر الأصلية؛ لا يُعد الملخص وحده دليلاً على صحة المعلومة.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _topicController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'موضوع البحث أو السؤال',
              hintText: 'مثال: فرص التصنيع الزراعي في السودان',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.lightbulb_outline)),
              title: const Text('AUREN Knowledge Hub'),
              subtitle: const Text('استكشف مجالات المعرفة ومسارات التعلم.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AurenKnowledgeHubScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.translate_outlined)),
              title: const Text('AUREN Language Bridge'),
              subtitle: const Text('ترجمة النصوص وفهم المصطلحات والسياق.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AurenLanguageBridgeScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._tools.map(
            (tool) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(child: Icon(tool.icon)),
                  title: Text(
                    tool.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(tool.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openTool(tool),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResearchTool {
  final String title;
  final String subtitle;
  final IconData icon;
  final String prompt;

  const _ResearchTool({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.prompt,
  });
}
