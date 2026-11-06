import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Open-source catalog and workflow entry point for NOVA's 3D game studio.
/// This screen links to upstream tools; it does not claim to install or run them
/// inside Android. Actual game builds require a desktop/CI environment.
class NovaGameStudioScreen extends StatelessWidget {
  const NovaGameStudioScreen({super.key});

  static const _tools = <_GameTool>[
    _GameTool('Claude Code Game Studios', 'وكلاء متخصّصون لتنظيم البرمجة والتصميم والفن والاختبار.', 'https://github.com/Donchitos/Claude-Code-Game-Studios', 'تنظيم الوكلاء', Icons.groups_outlined, 'مشروع موجّه إلى Claude Code؛ ليس تكاملاً جاهزاً مع Codex.'),
    _GameTool('Godot Engine', 'محرك ألعاب مفتوح المصدر للألعاب ثنائية وثلاثية الأبعاد.', 'https://github.com/godotengine/godot', 'المحرك الأساسي', Icons.videogame_asset_outlined, 'الخيار الأساسي المقترح للنموذج الأولي؛ راجع متطلبات التصدير لكل منصة.'),
    _GameTool('Blender MCP', 'جسر MCP للتحكم في Blender بمساعدة مساعد ذكاء اصطناعي.', 'https://github.com/ahujasid/mcp-server-blender', 'إنشاء الأصول', Icons.view_in_ar_outlined, 'يحتاج Blender وبيئة MCP على جهاز/خادم متوافق؛ لا يعمل بمجرد فتح الرابط.'),
    _GameTool('Terrain3D', 'نحت التضاريس وإنشاء عوالم طبيعية واسعة في Godot.', 'https://github.com/TokisanGames/Terrain3D', 'العوالم والتضاريس', Icons.landscape_outlined, 'تحقق من توافق نسخة الإضافة مع نسخة Godot المستخدمة.'),
    _GameTool('Godot Jolt', 'محرك فيزياء للأجسام الصلبة والتصادمات ثلاثية الأبعاد.', 'https://github.com/godot-jolt/godot-jolt', 'الفيزياء', Icons.sports_martial_arts_outlined, 'Godot 4.4+ يتضمن تكاملاً مع Jolt؛ تحقق مما إذا كانت الإضافة المستقلة لازمة.'),
    _GameTool('LimboAI', 'أشجار سلوك وآلات حالات لبناء سلوك الأعداء والشخصيات.', 'https://github.com/limbonaut/limboai', 'سلوك NPC', Icons.psychology_outlined, 'ذكاء سلوكي داخل اللعبة، وليس بالضرورة نموذجاً لغوياً.'),
    _GameTool('Dialogic', 'إنشاء حوارات وخيارات وقصص متفرعة.', 'https://github.com/dialogic-godot/dialogic', 'الحوار والسرد', Icons.forum_outlined, 'تأكد من دعم إصدار Godot قبل دمجه.'),
    _GameTool('Phantom Camera', 'إدارة كاميرات تتبع وانتقالات سينمائية في Godot.', 'https://github.com/ramokz/phantom-camera', 'الكاميرا السينمائية', Icons.movie_creation_outlined, 'راجع الوثائق والأمثلة الخاصة بالإصدار.'),
    _GameTool('meshoptimizer', 'تحسين بيانات المجسمات وتقليل كلفة هندسة الرسوم.', 'https://github.com/zeux/meshoptimizer', 'الأداء والتحسين', Icons.speed_outlined, 'مكتبة تحسين هندسي؛ تحتاج دمجاً في خط استيراد/بناء الأصول.'),
    _GameTool('Godot Demo Projects', 'أمثلة رسمية قابلة للدراسة والتعديل والتعلم.', 'https://github.com/godotengine/godot-demo-projects', 'التعلم من الأمثلة', Icons.school_outlined, 'ابدأ بمثال صغير قريب من نوع لعبتك ثم عدّله تدريجياً.'),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط؛ تحقق من الاتصال أو افتح الرابط يدوياً.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط؛ تحقق من الاتصال.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('NOVA · استوديو الألعاب ثلاثية الأبعاد')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF382B70), Color(0xFF202039)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.videogame_asset, size: 32, color: Color(0xFFB7A7FF)),
            SizedBox(height: 10),
            Text('من الفكرة إلى نموذج لعبة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('كتالوج أدوات مفتوحة المصدر وخط سير عملي. NOVA ينظم العمل ويفتح المصادر؛ لا يدّعي أن هذه الأدوات مثبّتة أو أن لعبة بُنيت بالفعل.'),
          ]),
        ),
        const SizedBox(height: 12),
        const _StepCard(number: '1', title: 'حدّد نطاقاً صغيراً', detail: 'ابدأ بمشهد واحد ولاعب واحد وهدف واضح، ثم سجّل متطلبات اللعبة.'),
        const _StepCard(number: '2', title: 'ابنِ النموذج في Godot', detail: 'استخدم مشروعاً تجريبياً رسمياً كأساس، واحفظ تغييراتك في Git.'),
        const _StepCard(number: '3', title: 'أضف الأدوات حسب الحاجة', detail: 'Blender للأصول، Terrain3D للعالم، LimboAI للسلوك، Dialogic للحوار، وJolt للفيزياء عند الحاجة.'),
        const _StepCard(number: '4', title: 'اختبر وحسّن', detail: 'اختبر المشاهد والتصادمات ومعدل الإطارات وحجم الأصول قبل توسيع المشروع.'),
        const SizedBox(height: 8),
        const Text('المشاريع العشرة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._tools.map((tool) => Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(child: Icon(tool.icon)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tool.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(tool.role, style: const TextStyle(color: Color(0xFFB7A7FF), fontWeight: FontWeight.w600)),
                ])),
              ]),
              const SizedBox(height: 8),
              Text(tool.description, textDirection: TextDirection.rtl),
              const SizedBox(height: 6),
              Text(tool.note, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Align(alignment: Alignment.centerLeft, child: TextButton.icon(
                onPressed: () => _open(context, tool.url),
                icon: const Icon(Icons.open_in_new),
                label: const Text('فتح المستودع الرسمي'),
              )),
            ]),
          ),
        )),
        const SizedBox(height: 8),
        const Card(child: Padding(
          padding: EdgeInsets.all(14),
          child: Text('ملاحظة مهمة: هاتف Android وحده ليس بيئة مريحة لبناء ألعاب 3D كاملة. يمكن استخدام NOVA على الهاتف للتخطيط ومراجعة الكود وفتح المستودعات، ثم تنفيذ البناء والاختبارات على جهاز مناسب أو CI. الأدوات مفتوحة المصدر لا تعني أن الاستضافة أو النماذج أو موارد البناء مجانية بلا حدود.', textDirection: TextDirection.rtl),
        )),
      ],
    ),
  );
}

class _GameTool {
  final String name;
  final String description;
  final String url;
  final String role;
  final IconData icon;
  final String note;
  const _GameTool(this.name, this.description, this.url, this.role, this.icon, this.note);
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String detail;
  const _StepCard({required this.number, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    leading: CircleAvatar(child: Text(number)),
    title: Text(title, textDirection: TextDirection.rtl),
    subtitle: Text(detail, textDirection: TextDirection.rtl),
  ));
}
