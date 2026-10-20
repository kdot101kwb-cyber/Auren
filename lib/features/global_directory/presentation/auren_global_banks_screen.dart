import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AurenGlobalBanksScreen extends StatefulWidget {
  const AurenGlobalBanksScreen({super.key});
  @override
  State<AurenGlobalBanksScreen> createState() => _AurenGlobalBanksScreenState();
}

class _AurenGlobalBanksScreenState extends State<AurenGlobalBanksScreen> {
  late final Future<List<Map<String, dynamic>>> _catalog = _load();
  String _query = '';
  String _region = 'الكل';
  String _kind = 'الكل';

  Future<List<Map<String, dynamic>>> _load() async {
    final decoded = jsonDecode(await rootBundle.loadString('assets/global_bank_institutions_v1.json')) as Map<String, dynamic>;
    return (decoded['institutions'] as List<dynamic>).whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الموقع الرسمي الآن.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN Global Banks')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('دليل عالمي أولي للبنوك ومؤسسات التمويل والجهات الرقابية. وجود المؤسسة هنا لا يعني أنها مرخّصة في بلدك أو أنها تقبل حسابات من جميع الدول. تحقق من الجهة الرقابية المحلية ومن الشروط والرسوم في المصدر الرسمي.'))),
      const SizedBox(height: 12),
      TextField(onChanged: (v) => setState(() => _query = v.trim().toLowerCase()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث بالاسم أو الدولة أو نوع الجهة', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _region, decoration: const InputDecoration(labelText: 'المنطقة', border: OutlineInputBorder()), items: const ['الكل','Africa','Europe','North America','Global'].map((v) => DropdownMenuItem(value: v, child: Text(v == 'الكل' ? 'كل المناطق' : v))).toList(), onChanged: (v) => setState(() => _region = v ?? 'الكل')),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _kind, decoration: const InputDecoration(labelText: 'نوع الجهة', border: OutlineInputBorder()), items: const ['الكل','commercial_banking_group','central_bank_regulator','development_finance','regional_development_finance','private_sector_development_finance','international_financial_institution'].map((v) => DropdownMenuItem(value: v, child: Text(v == 'الكل' ? 'كل الأنواع' : v.replaceAll('_', ' ')))).toList(), onChanged: (v) => setState(() => _kind = v ?? 'الكل')),
      const SizedBox(height: 12),
      FutureBuilder<List<Map<String, dynamic>>>(future: _catalog, builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        if (snap.hasError) return const Text('تعذر تحميل دليل البنوك. تحقق من إعدادات الأصول.');
        final rows = (snap.data ?? const <Map<String,dynamic>>[]).where((item) {
          final haystack = [item['name'],item['country'],item['kind'],item['note'],item['region']].join(' ').toLowerCase();
          return (_query.isEmpty || haystack.contains(_query)) && (_region == 'الكل' || item['region'] == _region) && (_kind == 'الكل' || item['kind'] == _kind);
        }).toList();
        if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('لا توجد نتائج مطابقة.'));
        return Column(children: rows.map((item) => Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.account_balance_outlined)),
          title: Text(item['name']?.toString() ?? 'Financial institution'),
          subtitle: Text('${item['country']} • ${item['status']}\n${item['note']}'),
          isThreeLine: true, trailing: const Icon(Icons.open_in_new),
          onTap: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Wrap(runSpacing: 12, children: [
            Text(item['name']?.toString() ?? 'Institution', style: Theme.of(ctx).textTheme.titleLarge),
            Text('الدولة/النطاق: ${item['country']}'),
            Text('نوع الجهة: ${item['kind']}'),
            Text('الحالة: ${item['status']}'),
            Text(item['note']?.toString() ?? ''),
            FilledButton.icon(onPressed: () { Navigator.pop(ctx); _open(item['website']?.toString() ?? ''); }, icon: const Icon(Icons.open_in_new), label: const Text('فتح الموقع الرسمي')),
          ]))))),
        )).toList());
      }),
      const SizedBox(height: 12),
      const Text('هذا دليل مؤسسات وليس توصية مالية. لا تُعرض أسعار أو شروط حسابات أو تأكيد ترخيص دون تحقق من مصدر رسمي حديث.', style: TextStyle(fontSize: 12)),
    ]),
  );
}
