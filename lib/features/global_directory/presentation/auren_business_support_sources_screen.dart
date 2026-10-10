import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auren_country_business_compliance_screen.dart';

class AurenBusinessSupportSourcesScreen extends StatefulWidget {
  const AurenBusinessSupportSourcesScreen({super.key});
  @override
  State<AurenBusinessSupportSourcesScreen> createState() => _AurenBusinessSupportSourcesScreenState();
}

class _AurenBusinessSupportSourcesScreenState extends State<AurenBusinessSupportSourcesScreen> {
  String _query = '';
  String _category = 'الكل';

  static const List<Map<String, String>> _sources = [
    {'name':'منظمة الجمارك العالمية','en':'World Customs Organization','category':'الجمارك والتجارة','scope':'دولي','topic':'المعايير والمعلومات العامة عن الإجراءات الجمركية','url':'https://www.wcoomd.org/','level':'منظمة دولية؛ لا تستبدل الجمارك الوطنية'},
    {'name':'منظمة التجارة العالمية','en':'World Trade Organization','category':'الجمارك والتجارة','scope':'دولي','topic':'اتفاقيات التجارة والسياسات التجارية للدول','url':'https://www.wto.org/','level':'مصدر دولي للمعلومات التجارية'},
    {'name':'UN Comtrade','en':'United Nations Comtrade','category':'الجمارك والتجارة','scope':'دولي','topic':'إحصاءات التجارة حسب السلعة والدولة','url':'https://comtradeplus.un.org/','level':'بيانات إحصائية وليست تصريح استيراد'},
    {'name':'مركز التجارة الدولية','en':'International Trade Centre','category':'الجمارك والتجارة','scope':'دولي','topic':'معلومات الأسواق والتعريفات ومتطلبات التجارة','url':'https://www.intracen.org/','level':'مصدر دعم تجاري؛ تحقق من الجمارك الوطنية'},
    {'name':'Access2Markets','en':'European Commission','category':'الجمارك والتجارة','scope':'الاتحاد الأوروبي','topic':'التعريفات ومتطلبات الاستيراد والتصدير إلى الاتحاد الأوروبي','url':'https://trade.ec.europa.eu/access-to-markets/','level':'بوابة رسمية للاتحاد الأوروبي'},
    {'name':'UK Trade Tariff','en':'UK Government','category':'الجمارك والتجارة','scope':'المملكة المتحدة','topic':'رموز السلع والرسوم والإجراءات الجمركية','url':'https://www.gov.uk/trade-tariff','level':'بوابة حكومية رسمية'},
    {'name':'U.S. Customs and Border Protection','en':'CBP','category':'الجمارك والتجارة','scope':'الولايات المتحدة','topic':'إجراءات الاستيراد والجمارك الأمريكية','url':'https://www.cbp.gov/trade','level':'جهة حكومية رسمية'},
    {'name':'Canada Border Services Agency','en':'CBSA','category':'الجمارك والتجارة','scope':'كندا','topic':'الاستيراد والتعريفات والإجراءات الحدودية','url':'https://www.cbsa-asfc.gc.ca/import/menu-eng.html','level':'جهة حكومية رسمية'},
    {'name':'Australian Border Force','en':'ABF','category':'الجمارك والتجارة','scope':'أستراليا','topic':'الاستيراد والجمارك والامتثال الحدودي','url':'https://www.abf.gov.au/importing-exporting-and-manufacturing','level':'جهة حكومية رسمية'},
    {'name':'Singapore Customs','en':'Singapore Customs','category':'الجمارك والتجارة','scope':'سنغافورة','topic':'التصاريح الجمركية والاستيراد والتصدير','url':'https://www.customs.gov.sg/','level':'جهة حكومية رسمية'},
    {'name':'هيئة الزكاة والضريبة والجمارك','en':'ZATCA','category':'الضرائب','scope':'السعودية','topic':'الضرائب والزكاة والجمارك والخدمات الإلكترونية','url':'https://zatca.gov.sa/','level':'جهة حكومية رسمية'},
    {'name':'HM Revenue & Customs','en':'HMRC','category':'الضرائب','scope':'المملكة المتحدة','topic':'التسجيل الضريبي وضريبة القيمة المضافة والالتزامات','url':'https://www.gov.uk/government/organisations/hm-revenue-customs','level':'جهة حكومية رسمية'},
    {'name':'Internal Revenue Service','en':'IRS','category':'الضرائب','scope':'الولايات المتحدة','topic':'المعلومات الضريبية للأعمال وأصحاب الشركات','url':'https://www.irs.gov/businesses','level':'جهة حكومية رسمية'},
    {'name':'Canada Revenue Agency','en':'CRA','category':'الضرائب','scope':'كندا','topic':'ضرائب الأعمال وحسابات الضرائب والتسجيل','url':'https://www.canada.ca/en/revenue-agency/services/tax/businesses.html','level':'جهة حكومية رسمية'},
    {'name':'Australian Taxation Office','en':'ATO','category':'الضرائب','scope':'أستراليا','topic':'الضرائب وتسجيل الأعمال وGST','url':'https://www.ato.gov.au/businesses-and-organisations','level':'جهة حكومية رسمية'},
    {'name':'South African Revenue Service','en':'SARS','category':'الضرائب','scope':'جنوب أفريقيا','topic':'ضرائب الأعمال والتخليص الجمركي','url':'https://www.sars.gov.za/','level':'جهة حكومية رسمية'},
    {'name':'Kenya Revenue Authority','en':'KRA','category':'الضرائب','scope':'كينيا','topic':'الضرائب والجمارك وخدمات المكلفين','url':'https://www.kra.go.ke/','level':'جهة حكومية رسمية'},
    {'name':'UNCTAD Investment Policy Hub','en':'UNCTAD','category':'الاستثمار','scope':'دولي','topic':'سياسات الاستثمار واتفاقيات الاستثمار حسب الدولة','url':'https://investmentpolicy.unctad.org/','level':'مصدر دولي؛ تحقق من القانون الوطني الساري'},
    {'name':'WAIPA','en':'World Association of Investment Promotion Agencies','category':'الاستثمار','scope':'دولي','topic':'الوصول إلى وكالات ترويج الاستثمار الوطنية','url':'https://waipa.org/','level':'شبكة وكالات وليست جهة ترخيص'},
    {'name':'Invest India','en':'Invest India','category':'الاستثمار','scope':'الهند','topic':'معلومات المستثمرين والقطاعات وفرص الاستثمار','url':'https://www.investindia.gov.in/','level':'وكالة ترويج الاستثمار الوطنية'},
    {'name':'WIPO','en':'World Intellectual Property Organization','category':'الملكية الفكرية','scope':'دولي','topic':'العلامات التجارية والبراءات والملكية الفكرية','url':'https://www.wipo.int/','level':'منظمة دولية؛ قد يلزم التسجيل المحلي'},
    {'name':'WIPO Global Brand Database','en':'WIPO','category':'الملكية الفكرية','scope':'دولي','topic':'البحث الأولي عن العلامات التجارية','url':'https://branddb.wipo.int/','level':'أداة بحث أولي وليست رأياً قانونياً'},
    {'name':'ISO','en':'International Organization for Standardization','category':'المعايير والجودة','scope':'دولي','topic':'معايير الجودة والسلامة والإدارة','url':'https://www.iso.org/','level':'الشهادات تصدر عبر جهات اعتماد مناسبة'},
    {'name':'Codex Alimentarius','en':'FAO/WHO Codex','category':'المعايير والجودة','scope':'دولي','topic':'معايير سلامة الغذاء والتجارة الغذائية','url':'https://www.fao.org/fao-who-codexalimentarius/','level':'تحقق من اشتراطات بلد الاستيراد'},
    {'name':'U.S. Food and Drug Administration','en':'FDA','category':'المعايير والجودة','scope':'الولايات المتحدة','topic':'متطلبات المنتجات الخاضعة لتنظيم FDA','url':'https://www.fda.gov/industry','level':'جهة تنظيمية أمريكية حسب نوع المنتج'},
    {'name':'EU product rules','en':'European Commission','category':'المعايير والجودة','scope':'الاتحاد الأوروبي','topic':'متطلبات المنتجات والامتثال للسوق الأوروبية','url':'https://single-market-economy.ec.europa.eu/single-market/goods_en','level':'مصدر رسمي للاتحاد الأوروبي'},
    {'name':'UN Global Marketplace','en':'UNGM','category':'المناقصات','scope':'دولي','topic':'فرص مشتريات ومناقصات منظومة الأمم المتحدة','url':'https://www.ungm.org/','level':'بوابة مشتريات دولية رسمية'},
    {'name':'World Bank Procurement','en':'World Bank','category':'المناقصات','scope':'دولي','topic':'فرص التوريد للمشروعات الممولة من البنك الدولي','url':'https://www.worldbank.org/en/projects-operations/products-and-services/procurement-projects-programs','level':'فرص مرتبطة بمشروعات البنك الدولي'},
    {'name':'SAM.gov Contract Opportunities','en':'SAM.gov','category':'المناقصات','scope':'الولايات المتحدة','topic':'فرص العقود والمناقصات الاتحادية الأمريكية','url':'https://sam.gov/content/opportunities','level':'بوابة حكومية؛ شروط الأهلية تختلف'},
    {'name':'TED Tenders Electronic Daily','en':'European Union','category':'المناقصات','scope':'الاتحاد الأوروبي','topic':'إعلانات المناقصات العامة الأوروبية','url':'https://ted.europa.eu/','level':'بوابة المناقصات الرسمية للاتحاد الأوروبي'},
    {'name':'African Development Bank Procurement','en':'AfDB','category':'المناقصات','scope':'أفريقيا','topic':'إعلانات مشتريات مشروعات البنك الأفريقي للتنمية','url':'https://www.afdb.org/en/projects-and-operations/procurement','level':'فرص مرتبطة بمشروعات البنك'},
  ];

  static const _categories = ['الكل','الجمارك والتجارة','الضرائب','الاستثمار','الملكية الفكرية','المعايير والجودة','المناقصات'];

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرابط غير صالح.')));
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الموقع الآن.')));
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final rows = _sources.where((item) {
      final haystack = [item['name'], item['en'], item['scope'], item['topic'], item['category']].join(' ').toLowerCase();
      return (_category == 'الكل' || item['category'] == _category) && (q.isEmpty || haystack.contains(q));
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('مصادر الأعمال والتجارة')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Icon(Icons.business_center_outlined, size: 32),
          SizedBox(height: 10),
          Text('من التأسيس إلى التشغيل والتوسع', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('دليل استكشاف للضرائب والجمارك والاستثمار والملكية الفكرية والمعايير والمناقصات. المصادر الدولية لا تحل محل الجهة الحكومية المختصة في بلدك أو السوق المستهدف.'),
        ]))),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AurenCountryBusinessComplianceScreen())),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('ملفات إجراءات وامتثال الأعمال حسب الدولة'),
        ),
        const SizedBox(height: 12),
        TextField(onChanged: (value) => setState(() => _query = value.trim()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث باسم الجهة أو الدولة أو الموضوع', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(labelText: 'نوع الخدمة', border: OutlineInputBorder()),
          items: _categories.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (value) => setState(() => _category = value ?? 'الكل'),
        ),
        const SizedBox(height: 12),
        Text('المصادر: ' + rows.length.toString(), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (rows.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('لا توجد نتائج مطابقة.')),
        ...rows.map((item) => Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.account_balance_outlined)),
          title: Text(item['name'] ?? ''),
          subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text((item['scope'] ?? '') + ' • ' + (item['category'] ?? '') + '\n' + (item['topic'] ?? '') + '\n' + (item['level'] ?? ''))),
          isThreeLine: true,
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _open(item['url'] ?? ''),
        ))),
        const SizedBox(height: 8),
        const Text('تحقق من أحدث التشريعات والرسوم وشروط الأهلية من الجهة المختصة قبل اتخاذ قرار أو دفع رسوم. هذا الدليل ليس استشارة قانونية أو ضريبية ولا يضمن أهلية أي شركة للمناقصات أو الاستثمار.', style: TextStyle(fontSize: 12)),
      ]),
    );
  }
}
