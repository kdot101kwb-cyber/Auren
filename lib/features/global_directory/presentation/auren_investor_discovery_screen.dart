import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Starting points for finding investors and funding programmes.
/// Availability and eligibility vary; this screen does not promise funding.
class AurenInvestorDiscoveryScreen extends StatefulWidget {
  const AurenInvestorDiscoveryScreen({super.key});

  @override
  State<AurenInvestorDiscoveryScreen> createState() => _AurenInvestorDiscoveryScreenState();
}

class _AurenInvestorDiscoveryScreenState extends State<AurenInvestorDiscoveryScreen> {
  final _queryController = TextEditingController();
  String _stage = 'الكل';

  static const _sources = <Map<String, String>>[
    {'name':'OpenVC','stage':'مستثمرون','focus':'البحث عن مستثمرين وصناديق رأس مال جريء وتجهيز التواصل','url':'https://www.openvc.app/'},
    {'name':'F6S','stage':'حاضنات ومسرّعات','focus':'برامج للشركات الناشئة ومسرّعات وفرص تقديم','url':'https://www.f6s.com/'},
    {'name':'VC4A','stage':'مستثمرون','focus':'منظومة الشركات الناشئة والمستثمرين والبرامج في الأسواق الناشئة وأفريقيا','url':'https://vc4a.com/'},
    {'name':'Gust','stage':'مستثمرون','focus':'أدوات ومنظومة للشركات الناشئة والمستثمرين الملائكيين','url':'https://gust.com/'},
    {'name':'IFC','stage':'تمويل تنموي','focus':'معلومات عن تمويل القطاع الخاص وبرامج الاستثمار؛ الأهلية تختلف حسب المشروع','url':'https://www.ifc.org/'},
    {'name':'African Development Bank','stage':'تمويل تنموي','focus':'برامج ومبادرات تمويل وتنمية في أفريقيا؛ تحقق من الدعوات وشروط الأهلية','url':'https://www.afdb.org/'},
    {'name':'Grants.gov','stage':'منح','focus':'بوابة المنح الفيدرالية الأمريكية؛ ليست متاحة لكل البلدان أو المتقدمين','url':'https://www.grants.gov/'},
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
      final matchesStage = _stage == 'الكل' || item['stage'] == _stage;
      final searchable = '${item['name']} ${item['focus']} ${item['stage']}'.toLowerCase();
      return matchesStage && searchable.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('المستثمرون والتمويل')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('اكتشف منصات المستثمرين والحاضنات وبعض بوابات التمويل. هذه نقاط بداية وليست عروض تمويل مؤكدة أو ضماناً لقبول طلبك.'),
          const SizedBox(height: 12),
          TextField(
            controller: _queryController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'ابحث حسب القطاع أو نوع التمويل',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _stage,
            decoration: const InputDecoration(labelText: 'نوع الفرصة', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'الكل', child: Text('كل الفرص')),
              DropdownMenuItem(value: 'مستثمرون', child: Text('مستثمرون')),
              DropdownMenuItem(value: 'حاضنات ومسرّعات', child: Text('حاضنات ومسرّعات')),
              DropdownMenuItem(value: 'تمويل تنموي', child: Text('تمويل تنموي')),
              DropdownMenuItem(value: 'منح', child: Text('منح')),
            ],
            onChanged: (value) => setState(() => _stage = value ?? 'الكل'),
          ),
          const SizedBox(height: 12),
          Text('المصادر المتاحة: ${rows.length}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (rows.isEmpty) const Text('لا توجد نتائج. جرّب كلمة بحث أخرى.'),
          ...rows.map((item) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.handshake_outlined)),
              title: Text(item['name']!),
              subtitle: Text('${item['stage']} • ${item['focus']}'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _open(item['url']!),
            ),
          )),
          const SizedBox(height: 12),
          const Text('جهّز ملخصاً تنفيذياً، وحجم التمويل المطلوب، واستخدام الأموال، وتوقعات مالية واقعية قبل التقديم. تحقق من الجهة والدعوة الرسمية ورسوم التقديم، ولا تدفع رسوماً لشخص يدّعي ضمان الاستثمار أو المنحة.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
