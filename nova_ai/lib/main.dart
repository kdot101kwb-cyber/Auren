import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const NovaApp());

const violet = Color(0xFF9B87FF);
const surface = Color(0xFF191925);

class NovaApp extends StatelessWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'NOVA AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: violet, brightness: Brightness.dark),
          scaffoldBackgroundColor: const Color(0xFF101018),
          cardTheme: CardThemeData(color: surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        ),
        home: const NovaHome(),
      );
}

class NovaHome extends StatefulWidget {
  const NovaHome({super.key});
  @override
  State<NovaHome> createState() => _NovaHomeState();
}

class _NovaHomeState extends State<NovaHome> {
  int tab = 0;
  String creativeMode = 'صور';
  final promptController = TextEditingController();
  final tasks = <String>[
    'فحص حالة مستودع AUREN',
    'إصلاح اختبارات Flutter الفاشلة',
    'تجهيز بناء Android قابل للتثبيت',
    'تأسيس وكلاء NOVA وسجل التنفيذ',
  ];
  final done = <bool>[false, false, false, false];

  @override
  void dispose() {
    promptController.dispose();
    super.dispose();
  }

  Future<void> open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط')));
    }
  }

  void prepareCreativeRequest() {
    final prompt = promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب وصفاً لما تريد إنشاءه أولاً')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تم التحقق من طلب $creativeMode. التوليد الفعلي يحتاج ربط محرك وخادم آمن؛ لم يتم إنشاء ملف بعد.'),
      duration: const Duration(seconds: 5),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      dashboard(),
      agents(),
      creativeStudio(),
      auren(),
      activity(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.auto_awesome, color: violet), SizedBox(width: 9), Text('NOVA AI', style: TextStyle(fontWeight: FontWeight.w800))]),
        actions: [IconButton(onPressed: () => showAboutDialog(context: context, applicationName: 'NOVA AI', applicationVersion: '0.2.0', children: const [Text('نسخة تأسيسية. أدوات الإبداع تحتاج ربط محركات التوليد عبر خادم آمن.')]), icon: const Icon(Icons.info_outline))],
      ),
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: 'الوكلاء'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'الإبداع'),
          NavigationDestination(icon: Icon(Icons.code_outlined), selectedIcon: Icon(Icons.code), label: 'AUREN'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'النشاط'),
        ],
      ),
    );
  }

  Widget dashboard() => ListView(padding: const EdgeInsets.all(16), children: [
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF382B70), Color(0xFF202039)]), borderRadius: BorderRadius.circular(22)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('مركز القيادة الذكي', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('إدارة NOVA وAUREN والوكلاء واستوديو الإبداع من مكان واحد.'),
      ]),
    ),
    const SizedBox(height: 16),
    const Row(children: [
      Expanded(child: _Metric(icon: Icons.smart_toy, title: 'الوكلاء', value: '6 أدوار مخططة')),
      SizedBox(width: 10),
      Expanded(child: _Metric(icon: Icons.auto_awesome, title: 'استوديو الإبداع', value: 'صور • فيديو • ألعاب')),
    ]),
    const SizedBox(height: 18),
    FilledButton.icon(onPressed: () => setState(() => tab = 2), icon: const Icon(Icons.auto_awesome), label: const Text('فتح استوديو الصور والفيديو والألعاب')),
    const SizedBox(height: 18),
    const Text('خطة العمل التالية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    ...List.generate(tasks.length, (i) => Card(child: CheckboxListTile(
      value: done[i],
      onChanged: (v) => setState(() => done[i] = v ?? false),
      title: Text(tasks[i], textDirection: TextDirection.rtl),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: violet,
    ))),
    const SizedBox(height: 8),
    const _Notice(text: 'تنبيه: حالة المهام أعلاه محلية على الهاتف حالياً. التنفيذ التلقائي والمزامنة يحتاجان إلى خادم آمن وربط GitHub.'),
  ]);

  Widget agents() => ListView(padding: const EdgeInsets.all(16), children: const [
    Text('فريق NOVA', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
    SizedBox(height: 6),
    Text('وكلاء متخصصون تحت إشراف المدير الرئيسي. هذه قائمة الأدوار المخططة؛ لم يتم تفعيل التنفيذ الآلي بعد.'),
    SizedBox(height: 12),
    _Agent(icon: Icons.account_tree, name: 'NOVA Manager', role: 'توزيع المهام ومتابعة النتائج'),
    _Agent(icon: Icons.code, name: 'وكيل التطوير', role: 'فحص الكود وتنفيذ الإصلاحات'),
    _Agent(icon: Icons.fact_check, name: 'وكيل الجودة', role: 'اختبارات Flutter وAndroid وCI'),
    _Agent(icon: Icons.security, name: 'وكيل الأمان', role: 'مراجعة Firebase والصلاحيات'),
    _Agent(icon: Icons.campaign, name: 'وكيل التسويق', role: 'المحتوى والنشر وتحليل الجمهور'),
    _Agent(icon: Icons.mail, name: 'وكيل البريد', role: 'فرز الرسائل وصياغة الردود'),
    _Notice(text: 'لن تُمنح الوكلاء صلاحيات غير محدودة. الربط الرسمي، أقل صلاحية لازمة، وسجل تدقيق وموافقة للعمليات الحساسة شروط أساسية.'),
  ]);

  Widget creativeStudio() => ListView(padding: const EdgeInsets.all(16), children: [
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF49317C), Color(0xFF202039)]), borderRadius: BorderRadius.circular(22)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.auto_awesome, size: 30, color: violet),
        SizedBox(height: 10),
        Text('استوديو NOVA الإبداعي', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('جهّز أفكار الصور والفيديو والألعاب في مساحة واحدة، مع قابلية إضافة أكثر من محرك توليد.'),
      ]),
    ),
    const SizedBox(height: 16),
    const Text('اختر نوع المشروع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _CreativeCard(icon: Icons.image_outlined, title: 'صور احترافية', subtitle: 'إعلانات، تصاميم، صور مصغرة', selected: creativeMode == 'صور', onTap: () => setState(() => creativeMode = 'صور')),
      const SizedBox(width: 8),
      Expanded(child: _CreativeCard(icon: Icons.movie_creation_outlined, title: 'فيديوهات', subtitle: 'مقاطع قصيرة ومشاهد', selected: creativeMode == 'فيديو', onTap: () => setState(() => creativeMode = 'فيديو')),
    ]),
    const SizedBox(height: 8),
    _CreativeCard(icon: Icons.sports_esports_outlined, title: 'ألعاب تفاعلية', subtitle: 'أفكار، تصميم مراحل، ونماذج ألعاب', selected: creativeMode == 'ألعاب', onTap: () => setState(() => creativeMode = 'ألعاب')),
    const SizedBox(height: 18),
    const Text('وصف فكرتك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    TextField(
      controller: promptController,
      minLines: 3,
      maxLines: 6,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: 'مثال: اصنع إعلاناً عمودياً أنيقاً لتطبيق تقني، بإضاءة سينمائية وألوان بنفسجية...',
        hintTextDirection: TextDirection.rtl,
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: prepareCreativeRequest, icon: const Icon(Icons.auto_awesome), label: Text('تجهيز طلب إنشاء $creativeMode')),
    const SizedBox(height: 12),
    const _Notice(text: 'الشفافية: هذه الواجهة تجهّز الفكرة فقط في النسخة الحالية ولا تُنتج ملفات صور أو فيديو أو ألعاب بعد. نحتاج ربط محركات فعلية عبر خادم آمن. لا يمكن ضمان توليد غير محدود حرفياً؛ يمكن تصميم النظام بلا حدّ يومي من التطبيق مع بقاء حدود مزوّد الخدمة والتكلفة والموارد.'),
    const SizedBox(height: 8),
    OutlinedButton.icon(onPressed: () => open('https://github.com/kdot101kwb-cyber/Auren/blob/feat/nova-ai-android-app/nova_ai/docs/open_source_blueprint.md'), icon: const Icon(Icons.menu_book_outlined), label: const Text('خطة محركات الذكاء الاصطناعي')),
  ]);

  Widget auren() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('إدارة مشروع AUREN', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('AUREN منصة Flutter موجهة للأفراد والشركات. سنكملها بالتوازي مع بناء NOVA.'),
    const SizedBox(height: 14),
    const _Metric(icon: Icons.phone_android, title: 'المنصة', value: 'Flutter / Android'),
    const SizedBox(height: 10),
    const _Metric(icon: Icons.cloud_outlined, title: 'الخدمات', value: 'Firebase + AI Gateway'),
    const SizedBox(height: 16),
    FilledButton.icon(onPressed: () => open('https://github.com/kdot101kwb-cyber/Auren'), icon: const Icon(Icons.open_in_new), label: const Text('فتح مستودع AUREN على GitHub')),
    const SizedBox(height: 8),
    OutlinedButton.icon(onPressed: () => open('https://github.com/kdot101kwb-cyber/Auren/issues/282'), icon: const Icon(Icons.assignment_outlined), label: const Text('فتح خطة التنفيذ')),
    const SizedBox(height: 14),
    const _Notice(text: 'المستودع لا يُنسخ بالكامل داخل APK؛ التطبيق يفتح المشروع المرتبط على GitHub. سيتم بناء تكامل آمن لإدارة المستودع بدلاً من تضمين الشيفرة المصدرية أو الأسرار داخل التطبيق.'),
  ]);

  Widget activity() => ListView(padding: const EdgeInsets.all(16), children: const [
    Text('سجل النشاط', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
    SizedBox(height: 10),
    _Activity(icon: Icons.check_circle_outline, title: 'تم تسجيل خطة NOVA + AUREN', detail: 'GitHub Issue #282'),
    _Activity(icon: Icons.account_tree_outlined, title: 'تم تجهيز هيكل واجهة NOVA', detail: 'لوحة رئيسية، وكلاء، استوديو الإبداع، AUREN، وسجل النشاط'),
    _Activity(icon: Icons.hourglass_empty, title: 'تكامل محركات التوليد والخادم', detail: 'لم يُنفّذ بعد؛ يتطلب مزودات فعلية وخدمة خلفية'),
    _Notice(text: 'سيظهر هنا سجل موثوق للعمليات بعد ربط التطبيق بالخادم. هذه العناصر حالياً توضح حالة التأسيس وليست سجلاً حياً للتنفيذ.'),
  ]);
}

class _CreativeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _CreativeCard({required this.icon, required this.title, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    color: selected ? const Color(0xFF30284E) : surface,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: violet, size: 28),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          if (selected) const Padding(padding: EdgeInsets.only(top: 8), child: Chip(avatar: Icon(Icons.check, size: 16), label: Text('محدد'))),
        ]),
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _Metric({required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: violet, size: 25), const SizedBox(height: 10), Text(title, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
  ])));
}

class _Agent extends StatelessWidget {
  final IconData icon;
  final String name;
  final String role;
  const _Agent({required this.icon, required this.name, required this.role});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFF30284E), child: Icon(icon, color: violet)), title: Text(name), subtitle: Text(role), trailing: const Chip(label: Text('مخطط'))));
}

class _Activity extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _Activity({required this.icon, required this.title, required this.detail});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon, color: violet), title: Text(title, textDirection: TextDirection.rtl), subtitle: Text(detail, textDirection: TextDirection.rtl)));
}

class _Notice extends StatelessWidget {
  final String text;
  const _Notice({required this.text});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.symmetric(vertical: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF282438), borderRadius: BorderRadius.circular(14)), child: Text(text, textDirection: TextDirection.rtl));
}
