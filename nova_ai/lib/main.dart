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
  final tasks = <String>[
    'فحص حالة مستودع AUREN',
    'إصلاح اختبارات Flutter الفاشلة',
    'تجهيز بناء Android قابل للتثبيت',
    'تأسيس وكلاء NOVA وسجل التنفيذ',
  ];
  final done = <bool>[false, false, false, false];

  Future<void> open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      dashboard(),
      agents(),
      auren(),
      activity(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.auto_awesome, color: violet), SizedBox(width: 9), Text('NOVA AI', style: TextStyle(fontWeight: FontWeight.w800))]),
        actions: [IconButton(onPressed: () => showAboutDialog(context: context, applicationName: 'NOVA AI', applicationVersion: '0.1.0', children: const [Text('نسخة أولية لمركز التحكم. يلزم ربط الخادم لتفعيل تنفيذ المهام والوكلاء فعلياً.')]), icon: const Icon(Icons.info_outline))],
      ),
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: 'الوكلاء'),
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
        Text('إدارة NOVA وAUREN من مكان واحد. تابع المهام والاختبارات والوكلاء.'),
      ]),
    ),
    const SizedBox(height: 16),
    const Row(children: [
      Expanded(child: _Metric(icon: Icons.smart_toy, title: 'الوكلاء', value: '6 مخططين')),
      SizedBox(width: 10),
      Expanded(child: _Metric(icon: Icons.rocket_launch, title: 'الإطلاق', value: 'قيد التجهيز')),
    ]),
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

  Widget agents() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('فريق NOVA', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
    const SizedBox(height: 6),
    const Text('وكلاء متخصصون تحت إشراف المدير الرئيسي. هذه قائمة الأدوار المخططة؛ لم يتم تفعيل التنفيذ الآلي بعد.'),
    const SizedBox(height: 12),
    const _Agent(icon: Icons.account_tree, name: 'NOVA Manager', role: 'توزيع المهام ومتابعة النتائج'),
    const _Agent(icon: Icons.code, name: 'وكيل التطوير', role: 'فحص الكود وتنفيذ الإصلاحات'),
    const _Agent(icon: Icons.fact_check, name: 'وكيل الجودة', role: 'اختبارات Flutter وAndroid وCI'),
    const _Agent(icon: Icons.security, name: 'وكيل الأمان', role: 'مراجعة Firebase والصلاحيات'),
    const _Agent(icon: Icons.campaign, name: 'وكيل التسويق', role: 'المحتوى والنشر وتحليل الجمهور'),
    const _Agent(icon: Icons.mail, name: 'وكيل البريد', role: 'فرز الرسائل وصياغة الردود'),
    const _Notice(text: 'لن تُمنح الوكلاء صلاحيات غير محدودة. الربط الرسمي، أقل صلاحية لازمة، وسجل تدقيق وموافقة للعمليات الحساسة هي شروط أساسية.'),
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
    _Activity(icon: Icons.account_tree_outlined, title: 'تم تجهيز هيكل واجهة NOVA', detail: 'لوحة رئيسية، وكلاء، AUREN، وسجل النشاط'),
    _Activity(icon: Icons.hourglass_empty, title: 'تكامل الخادم والوكلاء', detail: 'لم يُنفّذ بعد؛ يتطلب خدمة خلفية وصلاحيات آمنة'),
    _Notice(text: 'سيظهر هنا سجل موثوق للعمليات بعد ربط التطبيق بالخادم. هذه العناصر حالياً توضح حالة التأسيس وليست سجلاً حياً للتنفيذ.'),
  ]);
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
