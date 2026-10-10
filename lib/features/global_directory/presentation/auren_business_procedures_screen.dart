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
    {'country': 'السودان', 'countryEn': 'Sudan', 'region': 'أفريقيا', 'authority': 'وزارة العدل السودانية', 'topic': 'ابدأ من البوابة الحكومية للتحقق من الجهة المختصة بتسجيل الشركات والإجراءات السارية', 'url': 'https://www.moj.gov.sd/posts/post/64', 'level': 'صفحة وزارة العدل عن إدارة التسجيلات التجارية؛ تحقق من أحدث الإجراءات'},
    {'country': 'أوغندا', 'countryEn': 'Uganda', 'region': 'أفريقيا', 'authority': 'Uganda Registration Services Bureau', 'topic': 'تسجيل الشركات والأسماء التجارية والملكية الفكرية', 'url': 'https://ursb.go.ug/', 'level': 'بوابة الجهة الحكومية المختصة'},
    {'country': 'تنزانيا', 'countryEn': 'Tanzania', 'region': 'أفريقيا', 'authority': 'Business Registrations and Licensing Agency', 'topic': 'تسجيل الأعمال وخدمات السجل والتراخيص', 'url': 'https://www.brela.go.tz/', 'level': 'بوابة الجهة الحكومية المختصة'},
    {'country': 'زامبيا', 'countryEn': 'Zambia', 'region': 'أفريقيا', 'authority': 'Patents and Companies Registration Agency', 'topic': 'تسجيل الشركات والأسماء التجارية والملكية الفكرية', 'url': 'https://www.pacra.org.zm/', 'level': 'بوابة الجهة الحكومية المختصة'},
    {'country': 'بوتسوانا', 'countryEn': 'Botswana', 'region': 'أفريقيا', 'authority': 'Companies and Intellectual Property Authority', 'topic': 'تسجيل الشركات والملكية الفكرية', 'url': 'https://www.cipa.co.bw/', 'level': 'بوابة الجهة الحكومية المختصة'},
    {'country': 'ناميبيا', 'countryEn': 'Namibia', 'region': 'أفريقيا', 'authority': 'Business and Intellectual Property Authority', 'topic': 'تسجيل الشركات والملكية الفكرية', 'url': 'https://www.bipa.na/', 'level': 'بوابة الجهة الحكومية المختصة'},
    {'country': 'مصر', 'countryEn': 'Egypt', 'region': 'أفريقيا', 'authority': 'General Authority for Investment and Free Zones', 'topic': 'خدمات المستثمرين وتأسيس الشركات والمناطق الحرة', 'url': 'https://www.gafi.gov.eg/', 'level': 'بوابة حكومية رسمية'},
    {'country': 'المغرب', 'countryEn': 'Morocco', 'region': 'أفريقيا', 'authority': 'Office Marocain de la Propriété Industrielle et Commerciale', 'topic': 'معلومات السجل التجاري والملكية الصناعية والتجارية', 'url': 'https://www.ompic.ma/', 'level': 'بوابة الجهة الرسمية المختصة'},
    {'country': 'كوت ديفوار', 'countryEn': 'Côte d’Ivoire', 'region': 'أفريقيا', 'authority': 'Centre de Promotion des Investissements en Côte d’Ivoire', 'topic': 'معلومات الاستثمار ومرافقة تأسيس الأعمال', 'url': 'https://cepici.gouv.ci/', 'level': 'بوابة حكومية رسمية'},
    {'country': 'موريشيوس', 'countryEn': 'Mauritius', 'region': 'أفريقيا', 'authority': 'Corporate and Business Registration Department', 'topic': 'تسجيل الشركات والأعمال وخدمات السجل', 'url': 'https://companies.govmu.org/', 'level': 'بوابة حكومية رسمية'},
    {'country': 'السنغال', 'countryEn': 'Senegal', 'region': 'أفريقيا', 'authority': 'APIX — Invest in Senegal', 'topic': 'معلومات الاستثمار وإجراءات إنشاء الأعمال', 'url': 'https://investinsenegal.sn/', 'level': 'بوابة ترويج الاستثمار الرسمية'},
    {'country': 'إثيوبيا', 'countryEn': 'Ethiopia', 'region': 'أفريقيا', 'authority': 'Ethiopian Investment Commission', 'topic': 'معلومات الاستثمار وخدمات المستثمرين', 'url': 'https://investethiopia.gov.et/', 'level': 'بوابة حكومية رسمية'},
    {'country': 'جنوب السودان', 'countryEn': 'South Sudan', 'region': 'أفريقيا', 'authority': 'Business Registration Services — Ministry of Justice', 'topic': 'بوابة التسجيل التجاري والتحقق من بيانات الأعمال', 'url': 'https://brs.eservices.gov.ss/', 'level': 'بوابة حكومية لخدمات التسجيل'},
    {'country': 'الصومال', 'countryEn': 'Somalia', 'region': 'أفريقيا', 'authority': 'Ministry of Commerce and Industry', 'topic': 'تسجيل الأعمال والتراخيص التجارية', 'url': 'https://moci.gov.so/en/departments/licensing-business-registration/', 'level': 'صفحة رسمية للوزارة والجهة المختصة'},
    {'country': 'الجزائر', 'countryEn': 'Algeria', 'region': 'أفريقيا', 'authority': 'Centre National du Registre du Commerce', 'topic': 'السجل التجاري وإجراءات تسجيل النشاط', 'url': 'https://sidjilcom.cnrc.dz/', 'level': 'بوابة السجل التجاري؛ تحقق من الخدمات المتاحة'},
    {'country': 'تونس', 'countryEn': 'Tunisia', 'region': 'أفريقيا', 'authority': 'Registre National des Entreprises', 'topic': 'تسجيل المؤسسات والبحث في السجل الوطني', 'url': 'https://www.registre-entreprises.tn/', 'level': 'بوابة السجل الوطني للمؤسسات'},
    {'country': 'ملاوي', 'countryEn': 'Malawi', 'region': 'أفريقيا', 'authority': 'Department of Registrar General', 'topic': 'تسجيل الشركات والأسماء التجارية', 'url': 'https://www.registrargeneral.gov.mw/', 'level': 'بوابة الجهة الحكومية المختصة'},
    {'country': 'نيبال', 'countryEn': 'Nepal', 'region': 'آسيا', 'authority': 'Office of the Company Registrar', 'topic': 'تسجيل الشركات وخدمات مسجل الشركات', 'url': 'https://ocr.gov.np/', 'level': 'بوابة الجهة الحكومية المختصة'},
    {'country': 'تايلاند', 'countryEn': 'Thailand', 'region': 'آسيا', 'authority': 'Department of Business Development', 'topic': 'تسجيل الشركات والبيانات التجارية', 'url': 'https://www.dbd.go.th/', 'level': 'بوابة حكومية رسمية'},
    {'country': 'ماليزيا', 'countryEn': 'Malaysia', 'region': 'آسيا', 'authority': 'Companies Commission of Malaysia (SSM)', 'topic': 'تأسيس الشركات وخدمات السجل التجاري', 'url': 'https://www.ssm.com.my/', 'level': 'بوابة الجهة الحكومية المختصة'},
    {'country': 'سريلانكا', 'countryEn': 'Sri Lanka', 'region': 'آسيا', 'authority': 'Department of Registrar of Companies', 'topic': 'تسجيل الشركات والبحث في السجل', 'url': 'https://drc.gov.lk/', 'level': 'بوابة الجهة الحكومية المختصة'},
    {'country': 'باكستان', 'countryEn': 'Pakistan', 'region': 'آسيا', 'authority': 'Securities and Exchange Commission of Pakistan', 'topic': 'تسجيل الشركات والامتثال التنظيمي', 'url': 'https://www.secp.gov.pk/', 'level': 'بوابة الجهة التنظيمية الرسمية'},
    {'country': 'الفلبين', 'countryEn': 'Philippines', 'region': 'آسيا', 'authority': 'Securities and Exchange Commission', 'topic': 'تسجيل الشركات والامتثال المؤسسي', 'url': 'https://www.sec.gov.ph/', 'level': 'بوابة الجهة التنظيمية الرسمية'},
    {'country': 'نيوزيلندا', 'countryEn': 'New Zealand', 'region': 'أوقيانوسيا', 'authority': 'New Zealand Companies Register', 'topic': 'تسجيل الشركات والبحث في سجل الشركات', 'url': 'https://companies-register.companiesoffice.govt.nz/', 'level': 'سجل حكومي رسمي'},
    {'country': 'بابوا غينيا الجديدة', 'countryEn': 'Papua New Guinea', 'region': 'أوقيانوسيا', 'authority': 'Investment Promotion Authority', 'topic': 'تسجيل الشركات وخدمات الاستثمار', 'url': 'https://www.ipa.gov.pg/', 'level': 'بوابة الجهة الحكومية المختصة'},
    {'country': 'هولندا', 'countryEn': 'Netherlands', 'region': 'أوروبا', 'authority': 'Netherlands Chamber of Commerce (KVK)', 'topic': 'تسجيل الأعمال في سجل التجارة ومعلومات تأسيس الشركات', 'url': 'https://www.kvk.nl/english/', 'level': 'بوابة غرفة التجارة الرسمية'},
    {'country': 'النرويج', 'countryEn': 'Norway', 'region': 'أوروبا', 'authority': 'Brønnøysund Register Centre', 'topic': 'تسجيل الكيانات التجارية والبحث في السجلات', 'url': 'https://www.brreg.no/en/', 'level': 'بوابة السجلات الحكومية'},
    {'country': 'ألبانيا', 'countryEn': 'Albania', 'region': 'أوروبا', 'authority': 'National Business Center', 'topic': 'تسجيل الأعمال والبحث في سجل الشركات', 'url': 'https://qkb.gov.al/', 'level': 'بوابة الجهة الحكومية المختصة'},
    {'country': 'عُمان', 'countryEn': 'Oman', 'region': 'الشرق الأوسط', 'authority': 'Oman Business Platform', 'topic': 'تأسيس الأعمال والتسجيل والخدمات التجارية', 'url': 'https://business.gov.om/', 'level': 'بوابة حكومية لخدمات الأعمال'},
    {'country': 'بنما', 'countryEn': 'Panama', 'region': 'أمريكا الوسطى', 'authority': 'Registro Público de Panamá', 'topic': 'السجل العام وخدمات تسجيل الكيانات', 'url': 'https://www.rp.gob.pa/', 'level': 'بوابة السجل العام'},
    {'country': 'بيرو', 'countryEn': 'Peru', 'region': 'أمريكا الجنوبية', 'authority': 'SUNARP', 'topic': 'تسجيل الكيانات القانونية والبحث في السجلات', 'url': 'https://www.gob.pe/sunarp', 'level': 'بوابة حكومية رسمية'},
    {'country': 'كولومبيا', 'countryEn': 'Colombia', 'region': 'أمريكا الجنوبية', 'authority': 'Confecámaras', 'topic': 'معلومات السجل التجاري وغرف التجارة', 'url': 'https://www.confecamaras.org.co/', 'level': 'اتحاد غرف التجارة؛ تحقق من السجل المحلي المختص'},
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
