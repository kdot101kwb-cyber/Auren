import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AurenFinanceOpportunitiesScreen extends StatefulWidget {
  const AurenFinanceOpportunitiesScreen({super.key});

  @override
  State<AurenFinanceOpportunitiesScreen> createState() =>
      _AurenFinanceOpportunitiesScreenState();
}

class _AurenFinanceOpportunitiesScreenState
    extends State<AurenFinanceOpportunitiesScreen> {
  late final Future<List<Map<String, dynamic>>> _catalog = _loadCatalog();
  String _query = '';
  String _kind = 'الكل';
  String _region = 'الكل';

  static const _kinds = <String, String>{
    'الكل': 'all',
    'تمويل تنموي': 'development_finance',
    'قروض وضمانات': 'loans_and_guarantees',
    'منح ومناقصات': 'grants_and_tenders',
    'مناقصات ومشتريات': 'procurement',
    'دعم الأعمال': 'business_support',
    'استثمار وتمويل': 'loans_and_investment',
    'برامج إقليمية': 'regional_programs',
  };

  static const _regions = <String, String>{
    'الكل': 'all',
    'عالمي': 'global',
    'أفريقيا': 'africa',
    'الولايات المتحدة': 'united_states',
    'بريطانيا': 'united_kingdom',
    'الاتحاد الأوروبي': 'european_union',
  };

  Future<List<Map<String, dynamic>>> _loadCatalog() async {
    final decoded = jsonDecode(await rootBundle.loadString(
      'assets/global_finance_institutions_v1.json',
    )) as Map<String, dynamic>;
    return (decoded['institutions'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Future<void> _openOfficial(Map<String, dynamic> item) async {
    final uri = Uri.tryParse(item['website']?.toString() ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      _message('الرابط الرسمي غير متاح.');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _message('تعذر فتح الموقع الآن.');
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Finance & Opportunities')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(colors: [
                theme.colorScheme.primary.withValues(alpha: .24),
                theme.colorScheme.tertiary.withValues(alpha: .12),
              ]),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 36),
                SizedBox(height: 12),
                Text('تمويل موثوق يبدأ من المصدر',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  'دليل أولي لمؤسسات رسمية ومداخل البحث عن التمويل والمناقصات. لا يعني ظهور المؤسسة وجود منحة مفتوحة أو قبول طلبك.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'قبل التقديم: تحقق من الدولة المؤهلة، نوع التمويل، شروط الترخيص، الموعد النهائي، الرسوم، والمستندات في الموقع الرسمي. لا تدفع لوسيط مقابل وعد مضمون بالتمويل.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'ابحث عن مؤسسة أو نوع تمويل',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _kind,
            decoration: const InputDecoration(labelText: 'نوع الفرصة', border: OutlineInputBorder()),
            items: _kinds.keys.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _kind = v ?? 'الكل'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _region,
            decoration: const InputDecoration(labelText: 'النطاق الجغرافي', border: OutlineInputBorder()),
            items: _regions.keys.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _region = v ?? 'الكل'),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _catalog,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ));
              }
              if (snapshot.hasError) {
                return const Card(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('تعذر تحميل دليل المؤسسات.'),
                ));
              }
              final items = (snapshot.data ?? const <Map<String, dynamic>>[])
                  .where((item) {
                final kind = _kinds[_kind] ?? 'all';
                final region = _regions[_region] ?? 'all';
                final haystack = [
                  item['name'], item['description'], item['kind'],
                  item['region'], item['eligibility_note'], item['source_label'],
                ].join(' ').toLowerCase();
                return (_query.isEmpty || haystack.contains(_query)) &&
                    (kind == 'all' || item['kind'] == kind) &&
                    (region == 'all' || item['region'] == region);
              }).toList();
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('لا توجد نتائج مطابقة. جرّب تغيير المرشحات.'),
                );
              }
              return Column(
                children: items.map((item) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.account_balance_outlined)),
                    title: Text(item['name']?.toString() ?? 'مؤسسة'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['description']?.toString() ?? ''),
                          const SizedBox(height: 6),
                          Text('النطاق: ${_regionLabel(item['region']?.toString())}'),
                          Text('التصنيف: ${_statusLabel(item['offer_status']?.toString())}'),
                        ],
                      ),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _showDetails(item),
                  ),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'المعروض هو دليل مؤسسات ومداخل رسمية، وليس توصية استثمارية. لا تُعرض مبالغ أو مواعيد أو منح مفتوحة إلا بعد التحقق من إعلان رسمي محدد.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _regionLabel(String? value) => switch (value) {
    'global' => 'عالمي',
    'africa' => 'أفريقيا',
    'united_states' => 'الولايات المتحدة',
    'united_kingdom' => 'بريطانيا',
    'european_union' => 'الاتحاد الأوروبي',
    _ => 'غير محدد',
  };

  String _statusLabel(String? value) => switch (value) {
    'institution_information_only' => 'معلومات المؤسسة فقط',
    'information_only' => 'معلومات عامة',
    'country_specific_program_information' => 'برامج خاصة بدولة محددة',
    'opportunity_search_entry_point' => 'مدخل للبحث عن فرص',
    _ => 'تحقق من المصدر الرسمي',
  };

  void _showDetails(Map<String, dynamic> item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item['name']?.toString() ?? 'مؤسسة',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(item['description']?.toString() ?? ''),
                const SizedBox(height: 16),
                Text('نوع الجهة: ${item['source_label'] ?? 'غير محدد'}'),
                const SizedBox(height: 8),
                Text('حالة الفرصة: ${_statusLabel(item['offer_status']?.toString())}'),
                const SizedBox(height: 8),
                Text('الأهلية: ${item['eligibility_note'] ?? 'راجع الشروط الرسمية.'}'),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _openOfficial(item);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('فتح الموقع الرسمي'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
