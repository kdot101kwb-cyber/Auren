import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AurenGlobalCentralBanksScreen extends StatefulWidget {
  const AurenGlobalCentralBanksScreen({super.key});
  @override
  State<AurenGlobalCentralBanksScreen> createState() => _AurenGlobalCentralBanksScreenState();
}

class _AurenGlobalCentralBanksScreenState extends State<AurenGlobalCentralBanksScreen> {
  late final Future<Map<String, dynamic>> _catalog = _load();
  String _query = '';
  String _region = 'الكل';

  Future<Map<String, dynamic>> _load() async => jsonDecode(
    await rootBundle.loadString('assets/global_central_banks_v1.json'),
  ) as Map<String, dynamic>;

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر فتح الموقع الرسمي الآن.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('البنوك المركزية حول العالم')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || !snapshot.hasData) return const Center(child: Text('تعذر تحميل الدليل. حاول لاحقاً.'));
        final catalog = snapshot.data!;
        final all = (catalog['institutions'] as List<dynamic>).whereType<Map<String,dynamic>>();
        final rows = all.where((item) {
          final haystack = [item['name'],item['country'],item['region']].join(' ').toLowerCase();
          return (_query.isEmpty || haystack.contains(_query.toLowerCase())) && (_region == 'الكل' || item['region'] == _region);
        }).toList();
        final regions = ['الكل', ...((catalog['institutions'] as List<dynamic>).whereType<Map<String,dynamic>>().map((e) => e['region'].toString()).toSet().toList()..sort())];
        return ListView(padding: const EdgeInsets.all(16), children: [
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('دليل عالمي استكشافي لمواقع البنوك المركزية والسلطات النقدية، مبني على مرجع دولي. البنوك المركزية ليست بنوكاً تجارية للأفراد؛ استخدمها للتحقق من التنظيم والإعلانات والجهات المرخصة في كل دولة.'))),
          const SizedBox(height: 12),
          TextField(onChanged: (v) => setState(() => _query = v.trim()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث باسم الجهة أو الدولة', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _region, decoration: const InputDecoration(labelText: 'المنطقة', border: OutlineInputBorder()), items: regions.map((v) => DropdownMenuItem(value: v, child: Text(v == 'الكل' ? 'كل المناطق' : v))).toList(), onChanged: (v) => setState(() => _region = v ?? 'الكل')),
          const SizedBox(height: 12),
          Text('عدد النتائج: ${rows.length}', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...rows.map((item) => Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.account_balance_outlined)),
            title: Text(item['name']?.toString() ?? 'Central bank'),
            subtitle: Text('${item['country']} • ${item['region']}\nالمصدر التجميعي: BIS'),
            isThreeLine: true,
            trailing: const Icon(Icons.open_in_new),
            onTap: () => showModalBottomSheet<void>(context: context, builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Wrap(runSpacing: 12, children: [
              Text(item['name']?.toString() ?? 'Central bank', style: Theme.of(ctx).textTheme.titleLarge),
              Text('الدولة/النطاق: ${item['country']}'),
              Text('المنطقة: ${item['region']}'),
              const Text('هذا رابط الجهة النقدية وليس دليلاً على ترخيص بنك تجاري بعينه. تحقق من النطاق الرسمي والحالة الحالية.'),
              FilledButton.icon(onPressed: () { Navigator.pop(ctx); _open(item['website']?.toString() ?? ''); }, icon: const Icon(Icons.open_in_new), label: const Text('فتح الموقع الرسمي')),
              TextButton(onPressed: () { Navigator.pop(ctx); _open(catalog['source_url']?.toString() ?? ''); }, child: const Text('فتح دليل BIS')),
            ])))),
          ))),
        ]);
      },
    ),
  );
}
