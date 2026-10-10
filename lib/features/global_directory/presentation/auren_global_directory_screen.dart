import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../business/presentation/business_screen.dart';
import 'auren_start_business_screen.dart';
import 'auren_finance_opportunities_screen.dart';

class AurenGlobalDirectoryScreen extends StatefulWidget {
  const AurenGlobalDirectoryScreen({super.key});
  @override
  State<AurenGlobalDirectoryScreen> createState() => _AurenGlobalDirectoryScreenState();
}

class _AurenGlobalDirectoryScreenState extends State<AurenGlobalDirectoryScreen> {
  late final Future<List<Map<String, dynamic>>> _sources = _loadSources();
  String query = '';

  Future<List<Map<String, dynamic>>> _loadSources() async {
    final data = jsonDecode(await rootBundle.loadString(
      'functions/global_verified_api_registry_v1.json',
    )) as Map<String, dynamic>;
    return (data['apis'] as List<dynamic>).whereType<Map<String, dynamic>>().toList();
  }

  static const categories = <_DirectoryCategory>[
    _DirectoryCategory('الشركات والمصانع', 'صفحات الشركات والمصانع والمنتجات والخدمات وطلبات عروض الأسعار.', Icons.factory_outlined, ['ملف الشركة وموقعها', 'كتالوج المنتجات والخدمات', 'التواصل وطلب عرض سعر']),
    _DirectoryCategory('البنوك والخدمات المالية', 'البنوك والحسابات والخدمات التجارية حسب الدولة.', Icons.account_balance_outlined, ['الحسابات والخدمات التجارية', 'تمويل المنشآت والتجارة', 'الشروط وروابط التقديم الرسمية']),
    _DirectoryCategory('الاستثمار والتمويل', 'المنح والمستثمرون والقروض وبرامج دعم المشاريع.', Icons.trending_up_outlined, ['نوع التمويل والجهة', 'الدول المؤهلة والشروط', 'المواعيد والمصدر الرسمي']),
    _DirectoryCategory('الحكومة والإجراءات', 'مصادر رسمية لتسجيل الشركات والتراخيص والضرائب والجمارك.', Icons.policy_outlined, ['تسجيل الأعمال والتراخيص', 'الضرائب والاستيراد والتصدير', 'المستندات والرسوم من مصادر رسمية']),
    _DirectoryCategory('التجارة والاستيراد والتصدير', 'مصادر بيانات التجارة والأسواق لدعم قرارات الشراء والتصدير.', Icons.local_shipping_outlined, ['بيانات الاستيراد والتصدير', 'الأسواق والمنتجات', 'المتطلبات والمصادر الرسمية']),
    _DirectoryCategory('البيانات والمؤسسات العالمية', 'سجلات وبيانات اقتصادية ومؤسسية من جهات موثقة.', Icons.public_outlined, ['مصادر البيانات الرسمية', 'الدولة ونطاق التغطية', 'حالة التحقق والتكامل']),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Global Directory')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(colors: [
              theme.colorScheme.primary.withValues(alpha: .30),
              theme.colorScheme.tertiary.withValues(alpha: .16),
            ]),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.public, size: 34),
            SizedBox(height: 12),
            Text('العالم في صفحات مفيدة', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('اكتشف الشركات والمصانع والبنوك والفرص والمصادر الرسمية من مكان واحد. حالة التكامل موضحة بوضوح.'),
          ]),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.rocket_launch_outlined)),
            title: const Text('ابدأ مشروعك مع AUREN'),
            subtitle: const Text('خطوات أولية للبحث عن السوق والموردين والإجراءات والتمويل.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenStartBusinessScreen())),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.account_balance_wallet_outlined)),
            title: const Text('البنوك والتمويل والاستثمار'),
            subtitle: const Text('دليل مؤسسات رسمية ومداخل البحث عن المنح والتمويل والمناقصات.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenFinanceOpportunitiesScreen())),
          ),
        ),
        const SizedBox(height: 24),
        Text('استكشف حسب المجال', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...categories.map((category) => Card(child: ListTile(
          leading: CircleAvatar(child: Icon(category.icon)),
          title: Text(category.title),
          subtitle: Text(category.description),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => category.title == 'الشركات والمصانع'
                ? const AurenBusinessScreen()
                : _DirectoryCategoryPage(category: category),
          )),
        ))),
        const SizedBox(height: 20),
        Text('المصادر الرسمية المسجّلة', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('هذه القائمة تُحمّل مباشرة من سجل APIs الموجود في المشروع. وجود المصدر هنا لا يعني أن الاتصال الحي مفعّل.'),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => setState(() => query = value.trim().toLowerCase()),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث في أسماء المصادر ومجالاتها', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _sources,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
            if (snapshot.hasError) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('تعذر تحميل سجل المصادر. راجع إعدادات الأصول ثم أعد المحاولة.')));
            final rows = (snapshot.data ?? const <Map<String, dynamic>>[]).where((source) {
              final domains = (source['domains'] as List<dynamic>? ?? const []).join(' ');
              return '${source['name']} ${source['provider']} ${source['notes']} $domains'.toLowerCase().contains(query);
            }).toList();
            if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('لا توجد مصادر مطابقة.'));
            return Column(children: rows.map((source) => Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.source_outlined)),
              title: Text(source['name']?.toString() ?? 'مصدر رسمي'),
              subtitle: Text('${source['provider'] ?? ''}\nحالة التكامل: ${source['integration_status'] ?? 'غير محددة'}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ApiSourceDetailPage(source: source))),
            ))).toList());
          },
        ),
        const SizedBox(height: 12),
        const Text('البيانات العامة لا تعني موافقة الشركة على إدارة صفحتها، ولا تُمنح علامة التوثيق دون دليل. لا تُعرض جهات أو فرص وهمية.', style: TextStyle(fontSize: 12)),
      ]),
    );
  }
}

class _ApiSourceDetailPage extends StatelessWidget {
  const _ApiSourceDetailPage({required this.source});
  final Map<String, dynamic> source;

  Future<void> _openDocs(BuildContext context) async {
    final uri = Uri.tryParse(source['documentation_url']?.toString() ?? '');
    if (uri == null || uri.scheme != 'https') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رابط المصدر الرسمي غير متاح.')));
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط حالياً.')));
  }

  @override
  Widget build(BuildContext context) {
    final domains = (source['domains'] as List<dynamic>? ?? const []).map((v) => v.toString().replaceAll('_', ' ')).join(' • ');
    return Scaffold(appBar: AppBar(title: const Text('صفحة المصدر')), body: ListView(padding: const EdgeInsets.all(20), children: [
      const Icon(Icons.public, size: 44),
      const SizedBox(height: 12),
      Text(source['name']?.toString() ?? 'مصدر رسمي', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      Text(source['provider']?.toString() ?? ''),
      const SizedBox(height: 20),
      _InfoRow('المجالات', domains),
      _InfoRow('مستوى الوصول', source['access_tier']?.toString() ?? 'غير محدد'),
      _InfoRow('المصادقة', source['authentication']?.toString() ?? 'تحقق من المصدر'),
      _InfoRow('حالة التحقق', source['verification_status']?.toString() ?? 'غير محددة'),
      _InfoRow('حالة التكامل', source['integration_status']?.toString() ?? 'غير محددة'),
      _InfoRow('ملاحظات', source['notes']?.toString() ?? 'راجع التوثيق الرسمي.'),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: () => _openDocs(context), icon: const Icon(Icons.open_in_new), label: const Text('فتح التوثيق الرسمي')),
      const SizedBox(height: 10),
      const Text('قبل تفعيل أي تكامل، راجع شروط الاستخدام وحدود الطلبات وحداثة البيانات، واحفظ المفاتيح السرية في الخادم فقط.', style: TextStyle(fontSize: 12)),
    ]));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 3),
      SelectableText(value.isEmpty ? 'غير متوفر' : value),
      const Divider(height: 16),
    ]),
  );
}

class _DirectoryCategory {
  const _DirectoryCategory(this.title, this.description, this.icon, this.features);
  final String title, description;
  final IconData icon;
  final List<String> features;
}

class _DirectoryCategoryPage extends StatelessWidget {
  const _DirectoryCategoryPage({required this.category});
  final _DirectoryCategory category;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(category.title)),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      CircleAvatar(radius: 32, child: Icon(category.icon, size: 32)),
      const SizedBox(height: 16),
      Text(category.title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text(category.description),
      const SizedBox(height: 24),
      const Text('مكوّنات الصفحة'),
      const SizedBox(height: 8),
      ...category.features.map((feature) => Card(child: ListTile(leading: const Icon(Icons.check_circle_outline), title: Text(feature)))),
      const SizedBox(height: 12),
      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('هذه واجهة البداية. ستظهر النتائج عندما تتوفر مصادر فعلية موثوقة، مع الدولة وتاريخ التحديث وحالة التحقق.'))),
    ]),
  );
}
