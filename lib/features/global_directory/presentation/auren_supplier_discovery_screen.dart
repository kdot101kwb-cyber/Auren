import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Curated starting points for supplier discovery. Listings are not endorsements
/// and supplier identity, quality, stock, and payment terms must be checked.
class AurenSupplierDiscoveryScreen extends StatefulWidget {
  const AurenSupplierDiscoveryScreen({super.key});

  @override
  State<AurenSupplierDiscoveryScreen> createState() => _AurenSupplierDiscoveryScreenState();
}

class _AurenSupplierDiscoveryScreenState extends State<AurenSupplierDiscoveryScreen> {
  final _queryController = TextEditingController();
  String _category = 'الكل';

  static const _sources = <Map<String, String>>[
    {'name':'Alibaba.com','type':'مصادر دولية','focus':'مصنّعون وتجار جملة في قطاعات متعددة','url':'https://www.alibaba.com/'},
    {'name':'Global Sources','type':'مصادر دولية','focus':'مصادر ومصنّعون، خصوصاً الإلكترونيات والمنتجات الاستهلاكية','url':'https://www.globalsources.com/'},
    {'name':'Made-in-China.com','type':'مصادر دولية','focus':'مصنّعون ومورّدون من الصين في قطاعات متنوعة','url':'https://www.made-in-china.com/'},
    {'name':'Thomasnet','type':'مصادر صناعية','focus':'موردون ومصنّعون وخدمات صناعية في أمريكا الشمالية','url':'https://www.thomasnet.com/'},
    {'name':'Kompass','type':'دليل شركات','focus':'البحث عن شركات وموردين حسب النشاط والدولة','url':'https://www.kompass.com/'},
    {'name':'TradeKey','type':'تجارة دولية','focus':'دليل أعمال ومطابقة تجارية بين الشركات','url':'https://www.tradekey.com/'},
  ];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text.trim().toLowerCase();
    final rows = _sources.where((item) {
      final matchesCategory = _category == 'الكل' || item['type'] == _category;
      final searchable = '${item['name']} ${item['focus']} ${item['type']}'.toLowerCase();
      return matchesCategory && searchable.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('اكتشاف الموردين والمصادر')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('ابدأ من أدلة الموردين، ثم قارن عروض الأسعار وتحقق من الشركة قبل الدفع. ظهور المصدر هنا لا يعني التحقق من كل مورد داخله.'),
          const SizedBox(height: 12),
          TextField(
            controller: _queryController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'ابحث عن قطاع أو منصة أو نوع مورد',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'نوع المصدر', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'الكل', child: Text('كل المصادر')),
              DropdownMenuItem(value: 'مصادر دولية', child: Text('مصادر دولية')),
              DropdownMenuItem(value: 'مصادر صناعية', child: Text('مصادر صناعية')),
              DropdownMenuItem(value: 'دليل شركات', child: Text('دليل شركات')),
              DropdownMenuItem(value: 'تجارة دولية', child: Text('تجارة دولية')),
            ],
            onChanged: (value) => setState(() => _category = value ?? 'الكل'),
          ),
          const SizedBox(height: 12),
          Text('المصادر المتاحة: ${rows.length}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (rows.isEmpty) const Text('لا توجد نتائج. جرّب كلمة بحث أخرى.'),
          ...rows.map((item) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
              title: Text(item['name']!),
              subtitle: Text('${item['type']} • ${item['focus']}'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _open(item['url']!),
            ),
          )),
          const SizedBox(height: 12),
          const Text('قبل الشراء: تحقق من التسجيل والعنوان والمراجع والعينة وشروط الدفع والشحن. تجنب التحويلات غير القابلة للاسترجاع إلى حسابات شخصية، ولا تعتبر أي شارة على منصة ضماناً كاملاً.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
