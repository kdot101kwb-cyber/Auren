import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NovaAgentProject {
  const NovaAgentProject({
    required this.name,
    required this.repository,
    required this.role,
    required this.mode,
    required this.note,
  });

  final String name;
  final String repository;
  final String role;
  final String mode;
  final String note;

  String get url => 'https://github.com/$repository';
}

const novaAgentProjects = <NovaAgentProject>[
  NovaAgentProject(name: 'Open Jarvis', repository: 'tokenarc/open-jarvis', role: 'مساعد Android والتحكم بالتطبيقات', mode: 'مراجعة المصدر أولاً', note: 'مرشح لواجهة الصوت والمهارات والتحكم بموافقة المستخدم؛ يلزم التحقق من توافقه مع مشروع Flutter وترخيصه واعتمادياته.'),
  NovaAgentProject(name: 'Local-AI', repository: 'smartworldarafath/Local-AI', role: 'مساعد محلي وذاكرة واسترجاع معرفة', mode: 'مراجعة المصدر أولاً', note: 'مشروع Android مستقل؛ لا يُنسخ كاملاً داخل Flutter قبل تقييم الحجم والتراخيص وإمكانية إعادة استخدام وحداته.'),
  NovaAgentProject(name: 'llama.cpp', repository: 'ggml-org/llama.cpp', role: 'تشغيل نماذج اللغة محلياً', mode: 'مرشح لمحرك محلي', note: 'محرك C/C++ يحتاج طبقة Android/FFI متوافقة ونموذجاً كمياً مناسباً؛ حجم النموذج واستهلاك RAM غير مضمونين قبل اختبار الجهاز.'),
  NovaAgentProject(name: 'LangGraph', repository: 'langchain-ai/langgraph', role: 'تدفقات وكلاء ذات حالة وموافقات', mode: 'مرشح لخادم/منسق', note: 'إطار Python؛ لا يعمل مباشرة داخل Flutter، ويمكن أن يحتاج خدمة منفصلة أو منفذ Dart بديل.'),
  NovaAgentProject(name: 'smolagents', repository: 'huggingface/smolagents', role: 'وكلاء أدوات خفيفون', mode: 'مرشح لخادم/منسق', note: 'إطار Python. تنفيذ الشيفرة يحتاج عزلاً أمنياً حقيقياً؛ لا تشغّل شيفرة غير موثوقة على الجهاز مباشرة.'),
  NovaAgentProject(name: 'OpenHands', repository: 'OpenHands/OpenHands', role: 'وكيل تطوير وبناء تطبيقات', mode: 'مرشح لبيئة بناء معزولة', note: 'يحتاج بيئة تطوير منفصلة وموارد أكبر من الهاتف عادة؛ لا يُمنح صلاحية تعديل المستودع أو النشر دون موافقة.'),
  NovaAgentProject(name: 'Browser Use', repository: 'browser-use/browser-use', role: 'بحث الويب وأتمتة المتصفح', mode: 'مرشح عند الاتصال', note: 'وظائف البحث والتصفح تتطلب الإنترنت ومتصفحاً/خدمة متوافقة؛ لا يضمن مجانيتها أو العمل دون اتصال.'),
  NovaAgentProject(name: 'CrewAI', repository: 'crewAIInc/crewAI', role: 'تنسيق أدوار مجلس NOVA', mode: 'بديل لـ LangGraph', note: 'إطار Python لتنسيق عدة أدوار؛ لا نضيفه مع LangGraph تلقائياً حتى لا نكرر الوظيفة ونزيد التعقيد.'),
  NovaAgentProject(name: 'Android Agent', repository: 'ghost-in-the-droid/android-agent', role: 'اختبار وتحكم Android عبر ADB/MCP', mode: 'أداة تطوير واختبار', note: 'مناسب للاستكشاف والاختبار في بيئة مطور؛ ليس تكاملاً جاهزاً للتحكم الصامت بهاتف المستخدم.'),
  NovaAgentProject(name: 'Pocket Agents Lab', repository: 'cbarkinozer/pocket-agents-lab', role: 'تجارب وكلاء على الأجهزة المحمولة', mode: 'تجريبي', note: 'مشروع تجريبي؛ يُراجع للتعلم واستخلاص الأفكار ولا يُعتمد كمكوّن إنتاجي دون اختبارات إضافية.'),
];

class NovaAgentProjectsScreen extends StatelessWidget {
  const NovaAgentProjectsScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح مستودع GitHub')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مكتبة وكلاء NOVA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('تم تسجيل المشاريع العشرة في الكتالوج لتحديد وظيفة كل مشروع وخطوة الدمج المناسبة. التسجيل لا يعني أن الشيفرة الأصلية أو نماذج الذكاء الاصطناعي أصبحت مدمجة أو تعمل داخل التطبيق.'),
                  SizedBox(height: 8),
                  Text('الخطة: فحص الترخيص والاعتماديات، اختيار المكونات القابلة لإعادة الاستخدام، ثم الدمج على مراحل مع اختبارات Android وقياس الحجم والذاكرة.'),
                ],
              ),
            ),
          ),
          for (var i = 0; i < novaAgentProjects.length; i++)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(novaAgentProjects[i].name),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(novaAgentProjects[i].role),
                      const SizedBox(height: 4),
                      Text(novaAgentProjects[i].mode, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(novaAgentProjects[i].note),
                      const SizedBox(height: 6),
                      Text(novaAgentProjects[i].repository, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ),
                isThreeLine: false,
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _open(context, novaAgentProjects[i].url),
              ),
            ),
          const SizedBox(height: 12),
          const Text('ضوابط NOVA: لا أسرار داخل APK، لا تشغيل شيفرات غير موثوقة، ولا تحكم أو نشر أو تعديل خارجي دون موافقة واضحة من المستخدم.'),
        ],
      ),
    );
  }
}
