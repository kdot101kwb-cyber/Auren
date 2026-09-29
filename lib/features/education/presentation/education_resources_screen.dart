import 'package:flutter/material.dart';
import '../../../services/education/education_resource_catalog.dart';

class EducationResourcesScreen extends StatefulWidget {
  const EducationResourcesScreen({super.key});
  @override State<EducationResourcesScreen> createState() => _EducationResourcesScreenState();
}

class _EducationResourcesScreenState extends State<EducationResourcesScreen> {
  String q = ''; String type = 'All'; String language = 'All';
  @override Widget build(BuildContext context) {
    final list = EducationResourceCatalog.resources.where((r) {
      final text = '${r['name']} ${r['type']} ${r['subjects']} ${r['languages']}'.toLowerCase();
      return (q.isEmpty || text.contains(q.toLowerCase())) && (type == 'All' || r['type']!.contains(type));
    }).toList();
    return Scaffold(appBar: AppBar(title: const Text('مصادر التعلم')), body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(onChanged: (v) => setState(() => q = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'فيديو، كتاب، محاكاة، مختبر، دورة...'))),
      SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: ['All', ...EducationResourceCatalog.resourceTypes].map((x) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(x == 'All' ? 'الكل' : x), selected: type == x, onSelected: (_) => setState(() => type = x)))).toList())),
      SizedBox(height: 52, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(16), children: ['All', ...EducationResourceCatalog.languages].map((x) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(x == 'All' ? 'كل اللغات' : x), selected: language == x, onSelected: (_) => setState(() => language = x)))).toList())),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length, itemBuilder: (_, i) { final r = list[i]; return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.menu_book)), title: Text(r['name']!), subtitle: Text('${r['type']}\n${r['subjects']}\n${r['languages']}'), isThreeLine: true, trailing: const Icon(Icons.open_in_new))); })),
    ]));
  }
}
