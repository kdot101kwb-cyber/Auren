import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/education/education_resource_catalog.dart';

class EducationResourcesScreen extends StatefulWidget {
  final String initialSubject;
  final String? initialLanguage;
  const EducationResourcesScreen({super.key, this.initialSubject = '', this.initialLanguage});
  @override State<EducationResourcesScreen> createState() => _EducationResourcesScreenState();
}

class _EducationResourcesScreenState extends State<EducationResourcesScreen> {
  late String q; String type = 'All'; late String language;

  @override
  void initState() {
    super.initState();
    q = widget.initialSubject;
    language = widget.initialLanguage ?? 'All';
  }

  Future<void> _openResource(Map<String, String> resource) async {
    final raw = resource['url'];
    if (raw == null) return;
    final uri = Uri.tryParse(raw);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح المصدر الآن')),
      );
    }
  }

  @override Widget build(BuildContext context) {
    final list = EducationResourceCatalog.resources.where((r) {
      final text = '${r['name']} ${r['type']} ${r['subjects']} ${r['languages']}'.toLowerCase();
      final langText = (r['languages'] ?? '').toLowerCase();
      final wanted = language.toLowerCase();
      final languageMatch = language == 'All' || langText.contains(wanted) ||
          langText.contains('many languages') || langText.contains('65+ languages');
      return (q.isEmpty || text.contains(q.toLowerCase())) &&
          (type == 'All' || r['type']!.contains(type)) && languageMatch;
    }).toList();

    return Scaffold(appBar: AppBar(title: const Text('مصادر التعلم')), body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(
        onChanged: (v) => setState(() => q = v),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'فيديو، كتاب، محاكاة، مختبر، دورة...'),
      )),
      SizedBox(height: 48, child: ListView(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        children: ['All', ...EducationResourceCatalog.resourceTypes].map((x) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(label: Text(x == 'All' ? 'الكل' : x), selected: type == x,
            onSelected: (_) => setState(() => type = x)),
        )).toList(),
      )),
      SizedBox(height: 52, child: ListView(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(16),
        children: ['All', ...EducationResourceCatalog.languages].map((x) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(label: Text(x == 'All' ? 'كل اللغات' : x), selected: language == x,
            onSelected: (_) => setState(() => language = x)),
        )).toList(),
      )),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(16), itemCount: list.length,
        itemBuilder: (_, i) { final r = list[i]; return Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.menu_book)),
          title: Text(r['name']!),
          subtitle: Text('${r['type']}\n${r['subjects']}\n${r['languages']}'),
          isThreeLine: true,
          trailing: IconButton(tooltip: 'فتح المصدر', icon: const Icon(Icons.open_in_new),
            onPressed: () => _openResource(r)),
          onTap: () => _openResource(r),
        )); },
      )),
    ]));
  }
}