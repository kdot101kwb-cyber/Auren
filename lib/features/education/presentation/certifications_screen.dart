import 'package:flutter/material.dart';
import 'certification_catalog.dart';

class CertificationsScreen extends StatefulWidget {
  const CertificationsScreen({super.key});
  @override State<CertificationsScreen> createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends State<CertificationsScreen> {
  String query = ''; String provider = 'All';
  @override Widget build(BuildContext context) {
    final list = CertificationCatalog.certifications.where((c) {
      final q = query.toLowerCase();
      return (provider == 'All' || c['provider'] == provider) &&
          ('${c['name']} ${c['provider']} ${c['area']}'.toLowerCase().contains(q));
    }).toList();
    return Scaffold(appBar: AppBar(title: const Text('الشهادات العالمية')), body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن شهادة أو تخصص'))),
      SizedBox(height: 46, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: ['All', ...CertificationCatalog.providers].map((p) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(p == 'All' ? 'الكل' : p), selected: provider == p, onSelected: (_) => setState(() => provider = p)))).toList())),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length, itemBuilder: (_, i) { final c = list[i]; return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.workspace_premium)), title: Text(c['name']!), subtitle: Text('${c['provider']} • ${c['area']}'), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c['name']!, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), Text('مسار تعلّم للتحضير للشهادة مع AI Tutor، تمارين واختبارات ومتابعة التقدم.'), const SizedBox(height: 16), FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.play_arrow), label: const Text('ابدأ التحضير'))])))); })),
    ]));
  }
}
