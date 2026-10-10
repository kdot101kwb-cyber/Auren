import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AurenAfricanCentralBanksScreen extends StatefulWidget {
  const AurenAfricanCentralBanksScreen({super.key});
  @override
  State<AurenAfricanCentralBanksScreen> createState() => _AurenAfricanCentralBanksScreenState();
}

class _AurenAfricanCentralBanksScreenState extends State<AurenAfricanCentralBanksScreen> {
  late final Future<Map<String, dynamic>> _catalog = _load();
  String _query = '';
  String _region = 'الكل';

  Future<Map<String, dynamic>> _load() async => jsonDecode(
    await rootBundle.loadString('assets/africa_central_banks_v1.json'),
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
    appBar: AppBar(title: const Text('البنوك المركزية الأفريقية')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('تعذر تحميل الدليل. حاول لاحقاً.'));
        }
        final catalog = snapshot.data!;
        final all = (catalog['institutions'] as List<dynamic>).whereType<Map<String,dynamic>>();
        final rows = all.where((item) {
          final haystack = [item['name'],item['country'],item['region']].join(' ').toLowerCase();
          return (_query.isEmpty || haystack.contains(_query.toLowerCase())) &&
            (_region == 'الكل' || item['region'] == _region);
        }).toList();
        const regions = ['الكل','North Africa','West Africa','Central Africa','East Africa','Southern Africa'];
        return ListView(padding: const EdgeInsets.all(16), children: [
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('دليل استكشافي لمواقع البنوك المركزية والسلطات النقدية الأفريقية. استخدم هذه الجهات للتحقق من القواعد والتراخيص والإعلانات الرسمية؛ ليست هذه قائمة بالبنوك التجارية ولا ضماناً لصحة كل خدمة مصرفية.'))),
          const SizedBox(height: 12),
          TextField(onChanged: (v) => setState(() => _query = v.trim()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث باسم الجهة أو الدولة', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _region, decoration: const InputDecoration(labelText: 'الإقليم', border: OutlineInputBorder()), items: regions.map((v) => DropdownMenuItem(value: v, child: Text(v == 'الكل' ? 'كل الأقاليم' : v))).toList(), onChanged: (v) => setState(() => _region = v ?? 'الكل')),
          const SizedBox(height: 12),
          Text('عدد النتائج: ${rows.length}', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...rows.map((item) => Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.account_balance_outlined)),
            title: Text(item['name']?.toString() ?? 'Central bank'),
            subtitle: Text('${item['country']} • ${item['region']}\nتحقق من النطاق الرسمي قبل الاعتماد عليه'),
            isThreeLine: true,
            trailing: const Icon(Icons.open_in_new),
            onTap: () => showModalBottomSheet<void>(context: context, builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Wrap(runSpacing: 12, children: [
              Text(item['name']?.toString() ?? 'Central bank', style: Theme.of(ctx).textTheme.titleLarge),
              Text('الدولة/النطاق: ${item['country']}'),
              Text('الإقليم: ${item['region']}'),
              const Text('هذا رابط تعريفي للجهة الرقابية، وليس دليلاً على ترخيص بنك تجاري بعينه.'),
              FilledButton.icon(onPressed: () { Navigator.pop(ctx); _open(item['website']?.toString() ?? ''); }, icon: const Icon(Icons.open_in_new), label: const Text('فتح الموقع الرسمي')),
              TextButton(onPressed: () { Navigator.pop(ctx); _open(catalog['source_url']?.toString() ?? ''); }, child: const Text('فتح دليل جمعية البنوك المركزية الأفريقية')),
            ])))),
          ))),
          const SizedBox(height: 12),
          const Text('المصدر التجميعي: Association of African Central Banks (AACB). راجع موقع الجهة مباشرة لتأكيد الرابط والحالة الحالية.', style: TextStyle(fontSize: 12)),
        ]);
      },
    ),
  );
}
