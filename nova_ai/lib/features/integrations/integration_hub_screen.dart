import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'nova_tool_catalog.dart';

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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح صفحة الأداة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final categories = <String>['الكل', ...{for (final tool in novaToolCatalog) tool.category}];
    final filtered = novaToolCatalog.where((tool) {
      final matchesCategory = _category == 'الكل' || tool.category == _category;
      final haystack = '${tool.name} ${tool.description} ${tool.category}'.toLowerCase();
      return matchesCategory && (query.isEmpty || haystack.contains(query));
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF382B70), Color(0xFF202039)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.hub_outlined, color: _violet, size: 32),
            SizedBox(height: 10),
            Text('مركز أدوات NOVA', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('كتالوج من 50 أداة مختارة لبناء التطبيقات، البحث، الأتمتة، المحتوى، والتحليل. وجود الأداة في القائمة لا يعني أنها متصلة أو تعمل داخل NOVA.'),
          ]),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const Icon(Icons.verified_user_outlined, color: Colors.orangeAccent),
              const SizedBox(width: 10),
              Expanded(child: Text('الميزانية: صفر دولار. نبدأ بالأدوات المفتوحة المصدر أو ذات الحصة المجانية. مفاتيح API تحفظ بالخادم فقط، ولا نشر أو دفع أو معاملات مالية دون موافقة صريحة.')),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'ابحث عن أداة أو مهارة',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: const InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder()),
          items: categories.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
          onChanged: (value) => setState(() => _category = value ?? 'الكل'),
        ),
        const SizedBox(height: 12),
        Text('عرض ${filtered.length} من ${novaToolCatalog.length} أداة',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final tool in filtered)
          Card(
            color: _surface,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF30294F),
                    child: Icon(tool.icon, color: _violet, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${tool.id}. ${tool.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(tool.category, style: const TextStyle(color: _violet, fontSize: 12)),
                  ])),
                  const Chip(label: Text('غير مربوط'), visualDensity: VisualDensity.compact),
                ]),
                const SizedBox(height: 8),
                Text(tool.description, textDirection: TextDirection.rtl),
                const SizedBox(height: 6),
                Text(tool.setupNote, textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _open(context, tool.url),
                    icon: const Icon(Icons.open_in_new, size: 17),
                    label: const Text('فتح الموقع / التوثيق'),
                  ),
                ),
              ]),
            ),
          ),
        const SizedBox(height: 16),
        const Text('قاعدة التشغيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('لا تُعتبر الأداة متصلة إلا بعد تنفيذ اختبار فعلي وتسجيل النتيجة. الأدوات التي تتطلب استضافة أو API أو موافقة منصة ستبقى غير مفعّلة إلى أن تتوفر الشروط.'),
      ],
    );
  }
}
