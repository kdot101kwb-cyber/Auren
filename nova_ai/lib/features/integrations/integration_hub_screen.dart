import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _violet = Color(0xFF9B87FF);
const _surface = Color(0xFF191925);

class IntegrationHubScreen extends StatefulWidget {
  const IntegrationHubScreen({super.key});
  @override
  State<IntegrationHubScreen> createState() => _IntegrationHubScreenState();
}

class _IntegrationHubScreenState extends State<IntegrationHubScreen> {
  final _search = TextEditingController();
  String _category = 'الكل';

  static const _groups = <_ToolGroup>[
    _ToolGroup('برمجة وبناء التطبيقات', Icons.code, [
      _Tool('GitHub', 'مستودعات الكود والفروع وطلبات الدمج وActions', 'https://github.com/', 'التحكم الفعلي يحتاج API/OAuth'),
      _Tool('GitHub Copilot', 'مساعد كتابة الكود داخل بيئات التطوير المدعومة', 'https://github.com/features/copilot', 'الخطة المجانية وحدودها تتغير'),
      _Tool('Google AI Studio', 'تجربة نماذج Gemini وبناء نماذج أولية', 'https://aistudio.google.com/', 'الحصة المجانية حسب شروط Google'),
      _Tool('Google Antigravity', 'بيئة تطوير بمساعدة وكلاء ذكاء اصطناعي', 'https://antigravity.google/', 'تحقق من الإتاحة لحسابك'),
      _Tool('Cline', 'وكيل مفتوح المصدر لتعديل الكود وتشغيل الاختبارات', 'https://cline.bot/', 'يحتاج بيئة تشغيل ومزود نموذج'),
      _Tool('OpenCode', 'وكيل برمجي مع خيارات متعددة لمزودي النماذج', 'https://opencode.ai/', 'يحتاج بيئة تشغيل ومزود نموذج'),
      _Tool('Aider', 'مساعد برمجي يعمل مع مستودع Git', 'https://aider.chat/', 'يحتاج بيئة تشغيل'),
      _Tool('Continue', 'مساعد برمجي مفتوح المصدر للـ IDE', 'https://www.continue.dev/', 'يحتاج بيئة متوافقة'),
      _Tool('OpenHands', 'وكلاء تنفيذ مهام تطوير البرمجيات', 'https://github.com/All-Hands-AI/OpenHands', 'يحتاج استضافة ونموذج'),
      _Tool('Flutter', 'بناء تطبيقات Android وiOS والويب', 'https://flutter.dev/', 'البناء يحتاج Runner أو جهاز تطوير'),
      _Tool('DartPad', 'تجربة Dart وFlutter في المتصفح', 'https://dartpad.dev/', 'ليس بديلاً عن بناء APK كامل'),
      _Tool('Replit', 'كتابة وتشغيل تطبيقات ويب سحابياً', 'https://replit.com/', 'حدود المجانية تتغير'),
      _Tool('StackBlitz', 'تطوير تطبيقات ويب داخل المتصفح', 'https://stackblitz.com/', 'قد لا يدعم كل أنواع المشاريع'),
      _Tool('CodeSandbox', 'تجربة مشاريع الويب ومشاركتها', 'https://codesandbox.io/', 'قد يتطلب حساباً'),
    ]),
    _ToolGroup('التصميم والواجهات', Icons.design_services, [
      _Tool('Figma', 'تصميم الشاشات والنماذج الأولية', 'https://www.figma.com/', 'ميزات حسب الخطة'),
      _Tool('Penpot', 'تصميم واجهات مفتوح المصدر', 'https://penpot.app/', 'سحابي أو استضافة ذاتية'),
      _Tool('Canva', 'تصميم صور تسويقية وشعارات وصور مصغرة', 'https://www.canva.com/', 'بعض الميزات مدفوعة'),
      _Tool('Excalidraw', 'رسم مخططات تدفق وهيكل التطبيق', 'https://excalidraw.com/', 'للمخططات'),
      _Tool('diagrams.net', 'مخططات معمارية وقواعد بيانات', 'https://app.diagrams.net/', 'أداة مخططات'),
    ]),
    _ToolGroup('الخلفية وقواعد البيانات وAPI', Icons.storage, [
      _Tool('Firebase', 'مصادقة وقاعدة بيانات ووظائف خلفية', 'https://console.firebase.google.com/', 'NOVA يحتاج إعداداً واختباراً'),
      _Tool('Supabase', 'Postgres ومصادقة وتخزين وواجهات API', 'https://supabase.com/', 'حدود الخطة تتغير'),
      _Tool('Appwrite', 'خدمات خلفية مفتوحة المصدر', 'https://appwrite.io/', 'سحابي أو استضافة ذاتية'),
      _Tool('PocketBase', 'خلفية خفيفة لمشروعات صغيرة', 'https://pocketbase.io/', 'يتطلب خادماً'),
      _Tool('Postman', 'اختبار واجهات API', 'https://www.postman.com/', 'حدود حسب الخطة'),
      _Tool('Hoppscotch', 'اختبار API من المتصفح', 'https://hoppscotch.io/', 'قد يحتاج إعداد CORS'),
      _Tool('Swagger Editor', 'كتابة والتحقق من مواصفات OpenAPI', 'https://editor.swagger.io/', 'توثيق API'),
    ]),
    _ToolGroup('البناء والاختبار والنشر', Icons.build_circle, [
      _Tool('GitHub Actions', 'اختبارات وبناء APK وحفظ المخرجات', 'https://github.com/kdot101kwb-cyber/Auren/actions', 'تحقق من نتيجة كل تشغيل'),
      _Tool('CircleCI', 'تشغيل خطوط CI ومتابعة الاختبارات', 'https://circleci.com/', 'يلزم ربط المشروع'),
      _Tool('GitLab CI/CD', 'بناء واختبار ونشر المشاريع', 'https://gitlab.com/', 'يلزم ربط المستودع وRunner'),
      _Tool('Codemagic', 'بناء تطبيقات Flutter', 'https://codemagic.io/', 'الحدود والفوترة تتغير'),
      _Tool('SonarQube', 'تحليل جودة الكود', 'https://www.sonarsource.com/products/sonarqube/', 'قد يحتاج خدمة منفصلة'),
      _Tool('Sentry', 'رصد أخطاء التطبيق', 'https://sentry.io/', 'يلزم SDK ومشروع مهيأ'),
    ]),
    _ToolGroup('الألعاب وثلاثي الأبعاد', Icons.videogame_asset, [
      _Tool('Godot', 'محرك ألعاب مفتوح المصدر', 'https://godotengine.org/', 'التصدير يحتاج بيئة مناسبة'),
      _Tool('GDevelop', 'إنشاء ألعاب بقليل من الكود', 'https://gdevelop.io/', 'التصدير حسب الخطة'),
      _Tool('Unity', 'محرك ألعاب وتطبيقات تفاعلية', 'https://unity.com/', 'متطلبات الجهاز والترخيص تنطبق'),
      _Tool('Unreal Engine', 'ألعاب ورسوم ثلاثية الأبعاد', 'https://www.unrealengine.com/', 'يحتاج جهازاً قوياً'),
      _Tool('Blender', 'نمذجة وتحريك ورندر ثلاثي الأبعاد', 'https://www.blender.org/', 'برنامج سطح مكتب'),
      _Tool('Three.js', 'رسوم ثلاثية الأبعاد للويب', 'https://threejs.org/', 'يحتاج بيئة ويب'),
    ]),
    _ToolGroup('الصور والفيديو والصوت', Icons.movie_creation, [
      _Tool('ComfyUI', 'مسارات توليد صور ووسائط بنماذج مفتوحة', 'https://github.com/comfyanonymous/ComfyUI', 'يتطلب خادماً وموارد GPU غالباً'),
      _Tool('Hugging Face', 'استكشاف نماذج وبيانات ذكاء اصطناعي', 'https://huggingface.co/', 'حدود الاستدلال تختلف'),
      _Tool('Replicate', 'تشغيل نماذج صور وفيديو وصوت عبر API', 'https://replicate.com/', 'قد يتطلب الدفع'),
      _Tool('Remotion', 'إنشاء فيديو برمجياً باستخدام React', 'https://www.remotion.dev/', 'يتطلب Node.js وعامل بناء'),
      _Tool('MoviePy', 'تحرير الفيديو برمجياً في Python', 'https://zulko.github.io/moviepy/', 'يتطلب بيئة تشغيل'),
      _Tool('FFmpeg', 'تحويل ودمج ملفات الصوت والفيديو', 'https://ffmpeg.org/', 'يتطلب جهازاً أو خادماً'),
      _Tool('Audacity', 'تحرير الصوت وتسجيله', 'https://www.audacityteam.org/', 'برنامج مستقل'),
    ]),
    _ToolGroup('الأتمتة والذكاء الاصطناعي', Icons.account_tree, [
      _Tool('n8n', 'ربط الخدمات وبناء تدفقات أتمتة', 'https://n8n.io/', 'يحتاج إعداداً آمناً'),
      _Tool('Activepieces', 'أتمتة مفتوحة المصدر', 'https://www.activepieces.com/', 'يلزم إعداد الموصلات'),
      _Tool('Node-RED', 'تدفقات عمل مرئية وتكاملات', 'https://nodered.org/', 'يتطلب بيئة تشغيل'),
      _Tool('Dify', 'تطبيقات وسير عمل مدعوم بالذكاء الاصطناعي', 'https://dify.ai/', 'تكلفة النموذج والاستضافة منفصلة'),
      _Tool('Ollama', 'تشغيل نماذج محلية على جهاز مناسب', 'https://ollama.com/', 'لا يعمل داخل الهاتف تلقائياً'),
      _Tool('OpenRouter', 'واجهة موحدة لمزودي نماذج متعددين', 'https://openrouter.ai/', 'الحصص والأسعار تختلف'),
      _Tool('Brave Search API', 'بحث ويب قابل للدمج بالخادم', 'https://brave.com/search/api/', 'مفتاح وحدود استخدام مطلوبة'),
    ]),
    _ToolGroup('النشر والتسويق وإدارة المشروع', Icons.campaign, [
      _Tool('YouTube Studio', 'إدارة القناة ومراجعة التحليلات', 'https://studio.youtube.com/', 'النشر البرمجي يحتاج API'),
      _Tool('TikTok Developers', 'تكاملات النشر حسب أهلية الحساب', 'https://developers.tiktok.com/', 'الموافقة والصلاحيات مطلوبة'),
      _Tool('Meta for Developers', 'تكاملات Instagram وFacebook', 'https://developers.facebook.com/', 'الأهلية ومراجعة التطبيق مطلوبة'),
      _Tool('Buffer', 'جدولة محتوى المنصات المدعومة', 'https://buffer.com/', 'يلزم ربط الحساب'),
      _Tool('Notion', 'توثيق المشروع وخطط التنفيذ', 'https://www.notion.so/', 'ربط API يحتاج تفويضاً'),
      _Tool('Trello', 'لوحات مهام ومتابعة العمل', 'https://trello.com/', 'ربط API يحتاج تفويضاً'),
    ]),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(_Tool tool) async {
    final uri = Uri.parse(tool.url);
    if (uri.scheme != 'https') return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _InNovaBrowser(title: tool.name, uri: uri),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final groups = _groups.map((g) => _ToolGroup(g.title, g.icon, g.tools.where((t) =>
      (_category == 'الكل' || _category == g.title) &&
      (q.isEmpty || t.name.toLowerCase().contains(q) || t.description.toLowerCase().contains(q) || t.status.toLowerCase().contains(q))
    ).toList())).where((g) => g.tools.isNotEmpty).toList();
    final count = groups.fold<int>(0, (sum, g) => sum + g.tools.length);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF382B70), Color(0xFF202039)]), borderRadius: BorderRadius.circular(22)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.hub, color: _violet, size: 32),
            SizedBox(height: 10),
            Text('استوديو بناء التطبيقات داخل NOVA', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('كتالوج واحد للبرمجة والتصميم والخلفية والاختبار والألعاب والوسائط. افتح المواقع المتوافقة داخل NOVA وابحث دون مغادرة التطبيق.'),
          ]),
        ),
        const SizedBox(height: 12),
        TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(
          hintText: 'ابحث: Flutter، ألعاب، فيديو، API…', prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.clear)),
          border: const OutlineInputBorder(),
        )),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _category, isExpanded: true,
          decoration: const InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder()),
          items: ['الكل', ..._groups.map((g) => g.title)].map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _category = v ?? 'الكل'),
        ),
        const SizedBox(height: 8),
        Text('عدد الأدوات المعروضة: $count', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('هذا مركز دخول داخل NOVA وليس تثبيتاً لكل البرامج أو اتصال API جاهزاً. بعض المواقع تمنع المتصفح المدمج أو تتطلب تسجيل الدخول خارج التطبيق. لا تدخل كلمات المرور أو مفاتيح API في أدوات غير موثوقة.'))),
        for (final group in groups) ...[
          const SizedBox(height: 18),
          Row(children: [Icon(group.icon, color: _violet), const SizedBox(width: 8), Expanded(child: Text(group.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))]),
          const SizedBox(height: 8),
          for (final tool in group.tools)
            Card(color: _surface, child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.open_in_browser)),
              title: Text(tool.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tool.description), const SizedBox(height: 5),
                Text(tool.status, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
              ])),
              trailing: const Icon(Icons.chevron_left), onTap: () => _open(tool),
            )),
        ],
        if (groups.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد أدوات مطابقة. جرّب بحثاً آخر.'))),
        const SizedBox(height: 12),
        const Text('قواعد التنفيذ الآمن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('• مفاتيح API تحفظ في الخادم لا داخل Android.\n• البناء والنشر يحتاجان موصلات فعلية ونتائج اختبارات ناجحة.\n• لا نشر محتوى أو رسائل أو إنفاق مالي دون موافقتك.\n• المجانية وحدود الاستخدام تتغير؛ تحقق منها قبل اعتماد أي خدمة.'),
      ]),
    );
  }
}

class _InNovaBrowser extends StatefulWidget {
  const _InNovaBrowser({required this.title, required this.uri});
  final String title;
  final Uri uri;
  @override
  State<_InNovaBrowser> createState() => _InNovaBrowserState();
}

class _InNovaBrowserState extends State<_InNovaBrowser> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) { if (mounted) setState(() { _loading = true; _failed = false; }); },
        onPageFinished: (_) { if (mounted) setState(() => _loading = false); },
        onWebResourceError: (e) { if (e.isForMainFrame == true && mounted) setState(() { _loading = false; _failed = true; }); },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) return NavigationDecision.prevent;
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(widget.uri);
  }

  Future<void> _openExternal() async {
    final ok = await launchUrl(widget.uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الخدمة خارجياً')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title), actions: [
      IconButton(tooltip: 'إعادة التحميل', onPressed: () => _controller.reload(), icon: const Icon(Icons.refresh)),
      IconButton(tooltip: 'فتح خارج NOVA', onPressed: _openExternal, icon: const Icon(Icons.open_in_new)),
    ]),
    body: Stack(children: [
      WebViewWidget(controller: _controller),
      if (_loading) const LinearProgressIndicator(),
      if (_failed) Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.open_in_browser, size: 42), const SizedBox(height: 12),
        const Text('قد تمنع الخدمة العرض داخل التطبيقات أو تتطلب تسجيل دخول خارجي.'),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _openExternal, icon: const Icon(Icons.open_in_new), label: const Text('فتح في متصفح النظام')),
      ]))),
    ]),
  );
}

class _ToolGroup {
  final String title;
  final IconData icon;
  final List<_Tool> tools;
  const _ToolGroup(this.title, this.icon, this.tools);
}

class _Tool {
  final String name;
  final String description;
  final String url;
  final String status;
  const _Tool(this.name, this.description, this.url, this.status);
}
