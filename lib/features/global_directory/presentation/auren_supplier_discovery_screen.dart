import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auren_supplier_rfq_draft_screen.dart';
import 'auren_supplier_offer_comparison_screen.dart';

/// Curated starting points for supplier discovery. Listings are not endorsements
/// and supplier identity, quality, stock, and payment terms must be checked.
class AurenSupplierDiscoveryScreen extends StatefulWidget {
  const AurenSupplierDiscoveryScreen({super.key, this.auth, this.firestore});

  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  @override
  State<AurenSupplierDiscoveryScreen> createState() => _AurenSupplierDiscoveryScreenState();
}

class _AurenSupplierDiscoveryScreenState extends State<AurenSupplierDiscoveryScreen> {
  final _queryController = TextEditingController();
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  String _currency = 'USD';
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
    _productController.dispose();
    _quantityController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      _showOpenError();
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) _showOpenError();
    } catch (_) {
      _showOpenError();
    }
  }

  void _showOpenError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر فتح الموقع؛ تحقق من الاتصال أو افتحه من المتصفح.')),
    );
  }

  Future<void> _prepareRfq(
    String? sourceName, {
    String? product,
    String? quantity,
    String? destination,
    String? budget,
    String? currency,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AurenSupplierRfqDraftScreen(
          initialSupplier: sourceName,
          initialProduct: product,
          initialQuantity: quantity,
          initialDestination: destination,
          initialBudget: budget,
          initialCurrency: currency,
          auth: widget.auth,
          firestore: widget.firestore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text.trim().toLowerCase();
    final product = _productController.text.trim();
    final quantity = _quantityController.text.trim();
    final destination = _destinationController.text.trim();
    final budget = _budgetController.text.trim();
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
          Card(
            child: ListTile(
              leading: const Icon(Icons.compare_arrows_outlined),
              title: const Text('مقارنة عروض الأسعار المسجلة'),
              subtitle: const Text('سجّل العروض التي استلمتها وقارن التكلفة بالعملة نفسها.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AurenSupplierOfferComparisonScreen(
                    auth: widget.auth,
                    firestore: widget.firestore,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ابدأ من احتياجك', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  const Text('اكتب المنتج أو المادة المطلوبة، وسنجهّز لك مسودة طلب عرض سعر قابلة للتعديل. لا يتم إرسالها لأي مورد.'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _productController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                      hintText: 'مثال: ألواح شمسية أو بذور قمح',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _quantityController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.format_list_numbered),
                      hintText: 'الكمية المطلوبة (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _destinationController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on_outlined),
                      hintText: 'مدينة وبلد التسليم (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _budgetController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      hintText: 'الميزانية القصوى (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(
                      labelText: 'عملة الميزانية',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'SDG', child: Text('SDG')),
                      DropdownMenuItem(value: 'KES', child: Text('KES')),
                      DropdownMenuItem(value: 'NGN', child: Text('NGN')),
                    ],
                    onChanged: (value) => setState(() => _currency = value ?? 'USD'),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: product.isEmpty
                          ? null
                          : () => _prepareRfq(
                                null,
                                product: product,
                                quantity: quantity,
                                destination: destination,
                                budget: budget,
                                currency: _currency,
                              ),
                      icon: const Icon(Icons.request_quote_outlined),
                      label: const Text('جهّز طلب عرض سعر لاحتياجي'),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
                  title: Text(item['name']!),
                  subtitle: Text('${item['type']} • ${item['focus']}'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _open(item['url']!),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: OutlinedButton.icon(
                      onPressed: () => _prepareRfq(item['name']!),
                      icon: const Icon(Icons.request_quote_outlined),
                      label: const Text('جهّز طلب عرض سعر'),
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          const Text('قبل الشراء: تحقق من التسجيل والعنوان والمراجع والعينة وشروط الدفع والشحن. تجنب التحويلات غير القابلة للاسترجاع إلى حسابات شخصية، ولا تعتبر أي شارة على منصة ضماناً كاملاً.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
