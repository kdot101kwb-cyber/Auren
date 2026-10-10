import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AurenCountryBusinessComplianceScreen extends StatefulWidget {
  const AurenCountryBusinessComplianceScreen({super.key});
  @override
  State<AurenCountryBusinessComplianceScreen> createState() => _AurenCountryBusinessComplianceScreenState();
}

class _AurenCountryBusinessComplianceScreenState extends State<AurenCountryBusinessComplianceScreen> {
  String _country = 'السودان';
  String _query = '';

  static const List<Map<String, String>> _countries = [
    {'name':'السودان','region':'أفريقيا','registration':'https://www.moj.gov.sd/posts/post/64','tax':'https://www.mof.gov.sd/','customs':'https://customs.gov.sd/','investment':'https://invest.gov.sd/','note':'ابدأ بوزارة العدل للتحقق من التسجيلات التجارية، ثم تحقق مباشرة من الجهات الضريبية والجمركية والاستثمارية المختصة. قد تختلف الخدمات الإلكترونية المتاحة.'},
    {'name':'جنوب السودان','region':'أفريقيا','registration':'https://brs.eservices.gov.ss/','tax':'https://mofp.gov.ss/','customs':'https://mofp.gov.ss/','investment':'https://moci.gov.ss/','note':'تحقق من خدمات تسجيل الأعمال ومتطلبات الضرائب والاستيراد من الجهات الحكومية قبل تجهيز الطلب.'},
    {'name':'كينيا','region':'أفريقيا','registration':'https://brs.go.ke/','tax':'https://www.kra.go.ke/','customs':'https://www.kra.go.ke/','investment':'https://www.investkenya.go.ke/','note':'تحقق من تسجيل الشركة ورقم التعريف الضريبي والتراخيص الخاصة بالنشاط ومتطلبات الاستيراد عند الحاجة.'},
    {'name':'أوغندا','region':'أفريقيا','registration':'https://ursb.go.ug/','tax':'https://www.ura.go.ug/','customs':'https://www.ura.go.ug/','investment':'https://www.ugandainvest.go.ug/','note':'تحقق من تسجيل الكيان والضرائب والتصاريح المحلية أو القطاعية وإجراءات الجمارك حسب المنتج.'},
    {'name':'تنزانيا','region':'أفريقيا','registration':'https://www.brela.go.tz/','tax':'https://www.tra.go.tz/','customs':'https://www.tra.go.tz/','investment':'https://www.tic.go.tz/','note':'تحقق من نوع التسجيل المناسب والالتزامات الضريبية والتراخيص البلدية والقطاعية ومتطلبات الاستيراد.'},
    {'name':'رواندا','region':'أفريقيا','registration':'https://rdb.rw/','tax':'https://www.rra.gov.rw/','customs':'https://www.rra.gov.rw/','investment':'https://rdb.rw/','note':'استخدم بوابة الجهة الرسمية لتأكيد خطوات تسجيل النشاط والضرائب والتصاريح الخاصة بمجال عملك.'},
    {'name':'نيجيريا','region':'أفريقيا','registration':'https://www.cac.gov.ng/','tax':'https://www.firs.gov.ng/','customs':'https://customs.gov.ng/','investment':'https://www.nipc.gov.ng/','note':'تحقق من متطلبات الولاية والنشاط والتسجيلات الضريبية وأي موافقات استيراد أو تنظيم قطاعي.'},
    {'name':'غانا','region':'أفريقيا','registration':'https://orc.gov.gh/','tax':'https://gra.gov.gh/','customs':'https://gra.gov.gh/','investment':'https://gipc.gov.gh/','note':'تأكد من تسجيل الشركة والالتزامات الضريبية ومن شروط الاستثمار الأجنبي إن انطبقت.'},
    {'name':'مصر','region':'أفريقيا','registration':'https://www.gafi.gov.eg/','tax':'https://www.eta.gov.eg/','customs':'https://www.customs.gov.eg/','investment':'https://www.gafi.gov.eg/','note':'تحقق من الشكل القانوني للشركة والتسجيل الضريبي ومتطلبات الاستيراد والتراخيص القطاعية.'},
    {'name':'جنوب أفريقيا','region':'أفريقيا','registration':'https://www.cipc.co.za/','tax':'https://www.sars.gov.za/','customs':'https://www.sars.gov.za/','investment':'https://www.investsa.gov.za/','note':'راجع متطلبات تسجيل الكيان والضرائب والجمارك، ثم تحقق من التصاريح المهنية أو البلدية.'},
    {'name':'المغرب','region':'أفريقيا','registration':'https://www.ompic.ma/','tax':'https://www.tax.gov.ma/','customs':'https://www.douane.gov.ma/','investment':'https://www.micepp.gov.ma/','note':'تحقق من السجل التجاري والضرائب والجمارك والتصاريح حسب نوع المنتج أو الخدمة.'},
    {'name':'السنغال','region':'أفريقيا','registration':'https://investinsenegal.sn/','tax':'https://www.impotsetdomaines.gouv.sn/','customs':'https://www.douanes.sn/','investment':'https://investinsenegal.sn/','note':'تأكد من الجهة المسؤولة عن التسجيل والضرائب والجمارك واطلب تأكيداً رسمياً للرسوم الحالية.'},
    {'name':'الإمارات العربية المتحدة','region':'الشرق الأوسط','registration':'https://u.ae/en/information-and-services/business','tax':'https://tax.gov.ae/','customs':'https://u.ae/en/information-and-services/finance-and-investment','investment':'https://u.ae/en/information-and-services/business','note':'تختلف الرخصة والجهة المختصة بحسب الإمارة والمنطقة الحرة والنشاط؛ تحقق من شروط الملكية والتأشيرات والضرائب.'},
    {'name':'المملكة المتحدة','region':'أوروبا','registration':'https://www.gov.uk/set-up-business','tax':'https://www.gov.uk/government/organisations/hm-revenue-customs','customs':'https://www.gov.uk/trade-tariff','investment':'https://www.gov.uk/business-finance-support','note':'تحقق من التسجيل والضرائب والتراخيص والتزامات الاستيراد بحسب النشاط والسلع.'},
    {'name':'الولايات المتحدة','region':'أمريكا الشمالية','registration':'https://www.sba.gov/business-guide/launch-your-business','tax':'https://www.irs.gov/businesses','customs':'https://www.cbp.gov/trade','investment':'https://www.sba.gov/funding-programs','note':'تختلف المتطلبات بين المستوى الاتحادي والولاية والمدينة؛ راجع الجهات المناسبة لموقع النشاط ونوعه.'},
    {'name':'كندا','region':'أمريكا الشمالية','registration':'https://www.canada.ca/en/services/business/start.html','tax':'https://www.canada.ca/en/revenue-agency/services/tax/businesses.html','customs':'https://www.cbsa-asfc.gc.ca/import/menu-eng.html','investment':'https://www.canada.ca/en/services/business/grants.html','note':'تحقق مما إذا كان التسجيل اتحادياً أو إقليمياً ومن متطلبات الضرائب والتصاريح والاستيراد.'},
    {'name':'الهند','region':'آسيا','registration':'https://www.mca.gov.in/','tax':'https://www.incometax.gov.in/','customs':'https://www.cbic.gov.in/','investment':'https://www.investindia.gov.in/','note':'تحقق من شكل الكيان والتسجيلات الضريبية ورموز الاستيراد والتصدير والتراخيص القطاعية.'},
    {'name':'سنغافورة','region':'آسيا','registration':'https://www.acra.gov.sg/','tax':'https://www.iras.gov.sg/','customs':'https://www.customs.gov.sg/','investment':'https://www.edb.gov.sg/','note':'تحقق من متطلبات التأسيس والمديرين والعنوان والتسجيل الضريبي والتصاريح الخاصة بالنشاط.'},
    {'name':'أستراليا','region':'أوقيانوسيا','registration':'https://business.gov.au/guide/starting','tax':'https://www.ato.gov.au/businesses-and-organisations','customs':'https://www.abf.gov.au/importing-exporting-and-manufacturing','investment':'https://business.gov.au/grants-and-programs','note':'تحقق من التسجيلات الوطنية والولائية والضرائب والتراخيص ومتطلبات الاستيراد حسب النشاط.'},
  ];

  static const List<Map<String, String>> _steps = [
    {'title':'1. تحديد النشاط والملكية','detail':'حدد البلد والمدينة وطبيعة النشاط والملاك، وهل توجد ملكية أجنبية أو شريك محلي.'},
    {'title':'2. التسجيل القانوني','detail':'اختر الشكل القانوني بعد مراجعة الجهة الرسمية وجهّز الوثائق المطلوبة وفق قائمتها الحالية.'},
    {'title':'3. الضرائب والحسابات','detail':'تحقق من رقم التسجيل الضريبي وضريبة القيمة المضافة أو المبيعات إن انطبقت ومواعيد الإقرارات.'},
    {'title':'4. التراخيص القطاعية والمحلية','detail':'اسأل عن تصاريح البلدية والصحة والبيئة والعمل أو غيرها بحسب النشاط.'},
    {'title':'5. الاستيراد والتصدير','detail':'حدد رمز السلعة والمنشأ وشهادات المطابقة والتصاريح والرسوم الحالية لدى الجمارك الوطنية.'},
    {'title':'6. التمويل والمناقصات','detail':'تحقق من الأهلية والمستندات والمواعيد وشروط التسجيل لكل برنامج أو مناقصة بشكل منفصل.'},
  ];

  Future<void> _open(String? value) async {
    final uri = Uri.tryParse(value ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد رابط آمن صالح لهذا المصدر.')));
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الموقع الآن. حاول لاحقاً.')));
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final countries = _countries.where((item) => q.isEmpty || (item['name'] ?? '').toLowerCase().contains(q) || (item['region'] ?? '').toLowerCase().contains(q)).toList();
    final selected = _countries.firstWhere((item) => item['name'] == _country);
    final sources = [
      {'title':'تسجيل الشركات والأعمال','url':selected['registration']},
      {'title':'الضرائب والتسجيل الضريبي','url':selected['tax']},
      {'title':'الجمارك والاستيراد والتصدير','url':selected['customs']},
      {'title':'الاستثمار والتمويل','url':selected['investment']},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('ملف إجراءات الدولة')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.fact_check_outlined, size: 32),
          SizedBox(height: 8),
          Text('ملف امتثال الأعمال حسب الدولة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('يجمع الملف نقاط التحقق وروابط البداية الرسمية. لا يعرض رسوماً أو مواعيد أو حكماً قانونياً غير متحقق منه؛ أكد التفاصيل مع الجهة المختصة قبل الدفع أو تقديم المستندات.'),
        ]))),
        const SizedBox(height: 12),
        TextField(onChanged: (value) => setState(() => _query = value.trim()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن دولة أو منطقة', border: OutlineInputBorder())),
        if (_query.isNotEmpty)
          Wrap(
            spacing: 8,
            children: countries.take(8).map((item) {
              return ActionChip(
                label: Text(item['name'] ?? ''),
                onPressed: () => setState(() {
                  _country = item['name'] ?? _country;
                  _query = '';
                }),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _country, isExpanded: true,
          decoration: const InputDecoration(labelText: 'الدولة', border: OutlineInputBorder()),
          items: _countries.map((item) => DropdownMenuItem<String>(value: item['name'], child: Text((item['name'] ?? '') + ' — ' + (item['region'] ?? '')))).toList(),
          onChanged: (value) => setState(() => _country = value ?? _country),
        ),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(selected['note'] ?? ''))),
        Text('المصادر الرسمية للبدء', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...sources.map((source) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.open_in_new)), title: Text(source['title'] ?? ''), subtitle: Text(source['url'] ?? ''), onTap: () => _open(source['url'])))),
        const SizedBox(height: 8),
        Text('قائمة تحقق عامة', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._steps.map((step) => Card(child: ListTile(leading: const Icon(Icons.checklist_outlined), title: Text(step['title'] ?? ''), subtitle: Text(step['detail'] ?? ''), isThreeLine: true))),
        const SizedBox(height: 8),
        const Text('الروابط نقاط بداية وليست ضماناً بأن خدمة معينة تعمل حالياً أو أن المستخدم مؤهل لها. قد تختلف القوانين والرسوم حسب المنطقة والنشاط والجنسية والشكل القانوني. لا ترسل وثائق حساسة إلا عبر قناة حكومية آمنة بعد التأكد من صحة النطاق.', style: TextStyle(fontSize: 12)),
      ]),
    );
  }
}
