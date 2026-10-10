import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AurenBusinessProceduresScreen extends StatefulWidget {
  const AurenBusinessProceduresScreen({super.key});
  @override
  State<AurenBusinessProceduresScreen> createState() => _AurenBusinessProceduresScreenState();
}

class _AurenBusinessProceduresScreenState extends State<AurenBusinessProceduresScreen> {
  String _query = '';
  String _region = 'الكل';

  static const List<Map<String, String>> _sources = [
    {'country': 'كينيا', 'countryEn': 'Kenya', 'region': 'أفريقيا', 'authority': 'Business Registration Service', 'topic': 'تسجيل الشركات وخدمات السجل التجاري', 'url': 'https://brs.go.ke/', 'level': 'بوابة حكومية رسمية'},
    {'country': 'نيجيريا', 'countryEn': 'Nigeria', 'region': 'أفريقيا', 'authority': 'Corporate Affairs Commission', 'topic': 'تأسيس الشركات وحجز الأسماء وخدمات السجل', 'url': 'https://www.cac.gov.ng/', 'level': 'بوابة حكومية رسمية'},
    {'country': 'غانا', 'countryEn': 'Ghana', 'region': 'أفريقيا', 'authority': 'Office of the Registrar of Companies', 'topic': 'تسجيل الشركات والبحث في خدمات المسجل', 'url': 'https://orc.gov.gh/', 'level': 'بوابة حكومية رسمية'},
    {'country': 'رواندا', 'countryEn': 'Rwanda', 'region': 'أفريقيا', 'authority': 'Rwanda Development Board', 'topic': 'تسجيل الأعمال والاستثمار وخدمات المستثمرين', 'url': 'https://rdb.rw/', 'level': 'بوابة حكومية رسمية'},
    {'country': 'جنوب أفريقيا', 'countryEn': 'South Africa', 'region': 'أفريقيا', 'authority': 'Companies and Intellectual Property Commission', 'topic': 'تسجيل الشركات والملكية الفكرية', 'url': 'https://www.cipc.co.za/', 'level': 'بوابة حكومية رسمية'},
    {'country': 'المملكة المتحدة', 'countryEn': 'United Kingdom', 'region': 'أوروبا', 'authority': 'GOV.UK / Companies House', 'topic': 'بدء الأعمال وتسجيل الشركات والالتزامات', 'url': 'https://www.gov.uk/set-up-business', 'level': 'بوابة حكومية رسمية'},
    {'country': 'الاتحاد الأوروبي', 'countryEn': 'European Union', 'region': 'أوروبا', 'authority': 'Your Europe', 'topic': 'متطلبات تأسيس الأعمال والتراخيص والضرائب حسب الدولة', 'url': 'https://europa.eu/youreurope/business/', 'level': 'بوابة رسمية للاتحاد الأوروبي'},
    {'country': 'الولايات المتحدة', 'countryEn': 'United States', 'region': 'أمريكا الشمالية', 'authority': 'U.S. Small Business Administration', 'topic': 'خطوات تأسيس النشاط والتراخيص والتمويل', 'url': 'https://www.sba.gov/business-guide/launch-your-business', 'level': 'بوابة حكومية رسمية'},
    {'country': 'كندا', 'countryEn': 'Canada', 'region': 'أمريكا الشمالية', 'authority': 'Government of Canada', 'topic': 'بدء الأعمال والتسجيل والضرائب والتراخيص', 'url': 'https://www.canada.ca/en/services/business/start.html', 'level': 'بوابة حكومية رسمية'},
    {'country': 'أستراليا', 'countryEn': 'Australia', 'region': 'أوقيانوسيا', 'authority': 'business.gov.au', 'topic': 'التسجيل والتراخيص والضرائب وخطوات بدء النشاط', 'url': 'https://business.gov.au/guide/starting', 'level': 'بوابة حكومية رسمية'},
    {'country': 'الهند', 'countryEn': 'India', 'region': 'آسيا', 'authority': 'Ministry of Corporate Affairs', 'topic': 'تسجيل الشركات وخدمات وزارة شؤون الشركات', 'url': 'https://www.mca.gov.in/', 'level': 'بوابة حكومية رسمية'},
    {'country': 'سنغافورة', 'countryEn': 'Singapore', 'region': 'آسيا', 'authority': 'Accounting and Corporate Regulatory Authority', 'topic': 'تسجيل الكيانات التجارية والامتثال المؤسسي', 'url': 'https://www.acra.gov.sg/', 'level': 'بوابة حكومية رسمية'},
    {'country': 'الإمارات العربية المتحدة', 'countryEn': 'United Arab Emirates', 'region': 'الشرق الأوسط', 'authority': 'UAE Government Portal', 'topic': 'معلومات تأسيس الأعمال والتراخيص بحسب الإمارة والنشاط', 'url': 'https://u.ae/en/information-and-services/business', 'level': 'بوابة حكومية رسمية'},
  ];

  static const _regions = ['الكل', 'أفريقيا', 'أوروبا', 'أمريكا الشمالية', 'آسيا', 'الشرق الأوسط', 'أوقيانوسيا'];

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرابط الرسمي غير صالح.')));
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الموقع الرسمي الآن.')));
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final rows = _sources.where((item) {
      final haystack = [item['country'], item['countryEn'], item['authority'], item['topic'], item['region']].join(' ').toLowerCase();
      return (_region == 'الكل' || item['region'] == _region) && (q.isEmpty || haystack.contains(q));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('إجراءات تأسيس الأعمال')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Icon(Icons.policy_outlined, size: 32),
            SizedBox(height: 10),
            Text('مصادر حكومية لبدء مشروعك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('ابدأ من الجهة الرسمية في الدولة المستهدفة لمعرفة التسجيل والتراخيص والضرائب. تختلف الإجراءات حسب النشاط والمدينة ونوع الشركة، وقد تتغير؛ تحقق من المتطلبات والرسوم الحالية قبل التقديم.'),
          ]))),
          const SizedBox(height: 12),
          TextField(onChanged: (value) => setState(() => _query = value.trim()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث بالدولة أو الجهة أو الإجراء', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _region,
            decoration: const InputDecoration(labelText: 'المنطقة', border: OutlineInputBorder()),
            items: _regions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (value) => setState(() => _region = value ?? 'الكل'),
          ),
          const SizedBox(height: 12),
          Text('المصادر (' + rows.length.toString() + ')', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (rows.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('لا توجد نتائج مطابقة.')),
          ...rows.map((item) => Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.account_balance_outlined)),
            title: Text(item['country'] ?? ''),
            subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text((item['authority'] ?? '') + '\n' + (item['topic'] ?? '') + '\n' + (item['level'] ?? ''))),
            isThreeLine: true,
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _open(item['url'] ?? ''),
          ))),
          const SizedBox(height: 8),
          const Text('هذا دليل استكشاف وليس استشارة قانونية. لا يعني إدراج رابط أن AUREN تحققت من أهلية المستخدم أو أن الإجراء متاح لكل الجنسيات. لا تُرسل مستندات حساسة إلا عبر القنوات الرسمية الآمنة.', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
