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
    {'name':'اليابان','region':'آسيا','registration':'https://www.moj.go.jp/EN/MINJI/minji06.html','tax':'https://www.nta.go.jp/english/','customs':'https://www.customs.go.jp/english/','investment':'https://www.jetro.go.jp/en/invest/','note':'تحقق من إجراءات التسجيل لدى الجهات المختصة، ومتطلبات الضرائب والجمارك، وأي قواعد خاصة بالشكل القانوني أو الاستثمار الأجنبي.'},
    {'name':'كوريا الجنوبية','region':'آسيا','registration':'https://www.investkorea.org/ik-en/index.do','tax':'https://www.nts.go.kr/english/main.do','customs':'https://www.customs.go.kr/english/main.do','investment':'https://www.investkorea.org/ik-en/index.do','note':'تأكد من متطلبات تأسيس الشركة والتسجيل الضريبي والتراخيص القطاعية والجمارك من المصادر الحكومية الحالية.'},
    {'name':'إندونيسيا','region':'آسيا','registration':'https://oss.go.id/','tax':'https://www.pajak.go.id/en','customs':'https://www.beacukai.go.id/','investment':'https://www.bkpm.go.id/','note':'تحقق من نظام ترخيص الأعمال المناسب وتصنيف النشاط ومتطلبات الضرائب والاستيراد والقيود المتعلقة بالاستثمار.'},
    {'name':'فيتنام','region':'آسيا','registration':'https://dangkykinhdoanh.gov.vn/en/','tax':'https://www.gdt.gov.vn/wps/portal/english','customs':'https://www.customs.gov.vn/','investment':'https://investvietnam.gov.vn/','note':'تحقق من متطلبات تسجيل المؤسسة والاستثمار الأجنبي والضرائب والجمارك والتراخيص الخاصة بالقطاع.'},
    {'name':'ألمانيا','region':'أوروبا','registration':'https://www.existenzgruender.de/EN/Home/inhalt.html','tax':'https://www.bzst.de/EN/Home/home_node.html','customs':'https://www.zoll.de/EN/Home/home_node.html','investment':'https://www.gtai.de/en/invest','note':'قد تختلف إجراءات التسجيل والتراخيص محلياً؛ تحقق من مكتب التجارة والسلطات الضريبية والجمارك بحسب النشاط والموقع.'},
    {'name':'فرنسا','region':'أوروبا','registration':'https://formalites.entreprises.gouv.fr/','tax':'https://www.impots.gouv.fr/internationalenindividual','customs':'https://www.douane.gouv.fr/','investment':'https://www.businessfrance.fr/','note':'استخدم بوابة إجراءات الشركات والجهات الضريبية والجمركية الرسمية، وتحقق من المتطلبات المرتبطة بالنشاط والشكل القانوني.'},
    {'name':'تركيا','region':'أوروبا وآسيا','registration':'https://www.ticaret.gov.tr/','tax':'https://www.gib.gov.tr/','customs':'https://www.ticaret.gov.tr/gumruk-islemleri','investment':'https://www.invest.gov.tr/en/Pages/home.aspx','note':'تحقق من السجل التجاري والالتزامات الضريبية وإجراءات الاستيراد والتراخيص؛ قد تختلف الشروط بحسب النشاط والملكية.'},
    {'name':'البرازيل','region':'أمريكا الجنوبية','registration':'https://www.gov.br/empresas-e-negocios/pt-br','tax':'https://www.gov.br/receitafederal/en','customs':'https://www.gov.br/receitafederal/pt-br/assuntos/aduana-e-comercio-exterior','investment':'https://www.gov.br/pt-br/servicos/consultar-o-portal-do-investidor','note':'تحقق من التسجيل الفيدرالي والمحلي والضرائب والتراخيص والاشتراطات الجمركية وفق الولاية والمنتج.'},
    {'name':'المكسيك','region':'أمريكا الشمالية','registration':'https://www.gob.mx/tuempresa','tax':'https://www.sat.gob.mx/portal/public/home','customs':'https://www.sat.gob.mx/consulta/48977/aduanas','investment':'https://www.gob.mx/se/acciones-y-programas/inversion-extranjera-directa','note':'تختلف بعض المتطلبات حسب الولاية والبلدية؛ تحقق من التسجيل الضريبي والجمارك والقيود المحتملة على الاستثمار الأجنبي.'},
    {'name':'تشيلي','region':'أمريكا الجنوبية','registration':'https://www.registrodeempresasysociedades.cl/','tax':'https://www.sii.cl/portales/investors/registrese/','customs':'https://www.aduana.cl/aduana/site/edic/base/port/inicio.html','investment':'https://www.investchile.gob.cl/','note':'تحقق من إجراءات تأسيس الشركة والتسجيل الضريبي والتراخيص المحلية ومتطلبات الجمارك حسب طبيعة النشاط.'},
    {'name':'نيوزيلندا','region':'أوقيانوسيا','registration':'https://www.business.govt.nz/','tax':'https://www.ird.govt.nz/','customs':'https://www.customs.govt.nz/','investment':'https://www.nzte.govt.nz/','note':'تحقق من تسجيل الشركة والضرائب والتراخيص والاستيراد، ومن قواعد الاستثمار الأجنبي إن كانت ذات صلة.'},
    {'name':'الأرجنتين','region':'أمريكا الجنوبية','registration':'https://www.argentina.gob.ar/produccion/registrar-una-empresa','tax':'https://www.afip.gob.ar/','customs':'https://www.argentina.gob.ar/produccion/comercio-exterior','investment':'https://www.argentina.gob.ar/produccion','note':'تحقق من متطلبات التسجيل والضرائب والجمارك على المستوى الوطني والمحلي، إذ قد تختلف بحسب النشاط والموقع.'},
    {'name':'بيرو','region':'أمريكا الجنوبية','registration':'https://www.gob.pe/sunarp','tax':'https://www.sunat.gob.pe/','customs':'https://www.sunat.gob.pe/','investment':'https://www.investinperu.pe/','note':'راجع الجهات الرسمية لتسجيل الكيان ورقم التعريف الضريبي ومتطلبات الاستيراد والتصاريح الخاصة بالنشاط.'},
    {'name':'كولومبيا','region':'أمريكا الجنوبية','registration':'https://www.rues.org.co/','tax':'https://www.dian.gov.co/','customs':'https://www.dian.gov.co/','investment':'https://investincolombia.com.co/','note':'تحقق من التسجيل التجاري والضريبي والالتزامات الجمركية والتراخيص القطاعية قبل بدء النشاط.'},
    {'name':'كوستاريكا','region':'أمريكا الوسطى','registration':'https://www.rnpdigital.com/','tax':'https://www.hacienda.go.cr/','customs':'https://www.hacienda.go.cr/','investment':'https://www.procomer.com/','note':'تحقق من التسجيل التجاري والضرائب والجمارك والتراخيص المحلية من الجهات الرسمية الحالية.'},
    {'name':'بنما','region':'أمريكا الوسطى','registration':'https://www.panamaemprende.gob.pa/','tax':'https://dgi.mef.gob.pa/','customs':'https://www.ana.gob.pa/','investment':'https://propanama.gob.pa/','note':'تحقق من الرخصة التجارية والتسجيلات الضريبية وقواعد الاستيراد وأي شروط خاصة بالملكية الأجنبية.'},
    {'name':'المملكة العربية السعودية','region':'الشرق الأوسط','registration':'https://business.sa/','tax':'https://zatca.gov.sa/en/Pages/default.aspx','customs':'https://zatca.gov.sa/en/Pages/default.aspx','investment':'https://misa.gov.sa/','note':'تختلف المتطلبات بحسب النشاط والشكل القانوني والملكية؛ تحقق من الرخص والتسجيلات والضرائب والجمارك عبر الجهات المختصة.'},
    {'name':'قطر','region':'الشرق الأوسط','registration':'https://www.moci.gov.qa/en/','tax':'https://gta.gov.qa/en/','customs':'https://www.customs.gov.qa/English/Pages/default.aspx','investment':'https://www.invest.qa/','note':'تحقق من نوع الترخيص وشروط الملكية والموقع والنشاط والالتزامات الضريبية والجمركية الحالية.'},
    {'name':'البحرين','region':'الشرق الأوسط','registration':'https://www.moic.gov.bh/','tax':'https://www.nbr.gov.bh/','customs':'https://www.bahrain.bh/','investment':'https://www.bahrainedb.com/','note':'راجع نظام التسجيل التجاري والتراخيص والضرائب والجمارك وتأكد من أهلية النشاط وشروط المستثمر.'},
    {'name':'عُمان','region':'الشرق الأوسط','registration':'https://business.gov.om/','tax':'https://taxoman.gov.om/','customs':'https://www.customs.gov.om/','investment':'https://investoman.om/','note':'تحقق من التسجيل التجاري والتراخيص القطاعية والتزامات الضرائب والجمارك وشروط الاستثمار الأجنبي.'},
    {'name':'الأردن','region':'الشرق الأوسط','registration':'https://ccd.gov.jo/','tax':'https://istd.gov.jo/','customs':'https://www.customs.gov.jo/','investment':'https://www.moin.gov.jo/','note':'تحقق من شكل الشركة والتسجيل الضريبي ومتطلبات الاستيراد والتراخيص الخاصة بالنشاط لدى الجهات الحكومية.'},
    {'name':'إثيوبيا','region':'أفريقيا','registration':'https://www.motri.gov.et/','tax':'https://www.mofed.gov.et/','customs':'https://www.erca.gov.et/','investment':'https://investethiopia.gov.et/','note':'تحقق من الجهة الحكومية المختصة حالياً بتسجيل الأعمال والضرائب والجمارك والاستثمار، لأن الاختصاصات والبوابات قد تتغير.'},
    {'name':'زامبيا','region':'أفريقيا','registration':'https://www.pacra.org.zm/','tax':'https://www.zra.org.zm/','customs':'https://www.zra.org.zm/','investment':'https://www.zda.org.zm/','note':'تحقق من تسجيل الشركة والضرائب والجمارك والتراخيص الخاصة بالنشاط من الجهات الرسمية قبل تقديم الطلب.'},
    {'name':'بوتسوانا','region':'أفريقيا','registration':'https://www.cipa.co.bw/','tax':'https://www.burs.org.bw/','customs':'https://www.burs.org.bw/','investment':'https://www.bitc.co.bw/','note':'تأكد من متطلبات التسجيل والتصاريح والضرائب والجمارك، خصوصاً إذا كان النشاط يتضمن استيراداً أو ملكية أجنبية.'},
    {'name':'ناميبيا','region':'أفريقيا','registration':'https://www.bipa.na/','tax':'https://www.itas.namra.org.na/','customs':'https://www.namra.org.na/','investment':'https://www.nipdb.com/','note':'راجع الجهات المختصة للتسجيل والضرائب والجمارك وتراخيص القطاع قبل الاعتماد على أي رسوم أو مدد.'},
    {'name':'موريشيوس','region':'أفريقيا','registration':'https://companies.govmu.org/','tax':'https://www.mra.mu/','customs':'https://www.mra.mu/','investment':'https://www.edbmauritius.org/','note':'تحقق من نوع الكيان والتسجيل الضريبي والجمارك والتراخيص وشروط الاستثمار المناسبة لنشاطك.'},
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
