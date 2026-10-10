import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auren_trade_deal_screen.dart';

enum AurenBusinessResourceType {
  factories,
  companies,
  banks,
  exportImport,
}

class AurenBusinessResourceScreen extends StatefulWidget {
  const AurenBusinessResourceScreen({
    super.key,
    required this.type,
  });

  final AurenBusinessResourceType type;

  @override
  State<AurenBusinessResourceScreen> createState() =>
      _AurenBusinessResourceScreenState();
}

class _AurenBusinessResourceScreenState
    extends State<AurenBusinessResourceScreen> {
  final _queryController = TextEditingController();
  final Set<String> _completedChecklistItems = <String>{};
  bool _checklistLoaded = false;

  String get _checklistStorageKey {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'auren_business_checklist_v1_${userId}_${widget.type.index}';
  }

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_checklistStorageKey) ?? <String>[];
      if (!mounted) return;
      _completedChecklistItems
        ..clear()
        ..addAll(saved.where((item) => _checklist.contains(item)));
    } catch (_) {
      // Checklist remains usable in memory if local storage is unavailable.
    } finally {
      if (mounted) setState(() => _checklistLoaded = true);
    }
  }

  Future<void> _persistChecklist() async {
    if (!_checklistLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _checklistStorageKey,
        _completedChecklistItems.toList(),
      );
    } catch (_) {
      // Keep the current checklist state for this screen session.
    }
  }

  String get _title {
    switch (widget.type) {
      case AurenBusinessResourceType.factories:
        return 'اكتشاف المصانع';
      case AurenBusinessResourceType.companies:
        return 'دليل الشركات';
      case AurenBusinessResourceType.banks:
        return 'البنوك وتمويل التجارة';
      case AurenBusinessResourceType.exportImport:
        return 'التصدير والاستيراد';
    }
  }

  String get _intro {
    switch (widget.type) {
      case AurenBusinessResourceType.factories:
        return 'ابدأ بالبحث عن المصانع والمصنّعين ومقدمي التصنيع التعاقدي. هذه أدلة خارجية وليست سجلاً موحداً أو تأكيداً لجودة أي مصنع.';
      case AurenBusinessResourceType.companies:
        return 'استخدم أدلة الأعمال للعثور على شركات وموزعين ووكلاء وشركاء محتملين. تحقق من التسجيل والعنوان والملكية قبل التعاقد.';
      case AurenBusinessResourceType.banks:
        return 'مصادر أولية للتعرف على تمويل التجارة والخطابات والضمانات وشبكات البنوك. توفر الخدمة والأهلية يعتمدان على بلدك والبنك والصفقة.';
      case AurenBusinessResourceType.exportImport:
        return 'ابدأ بتحديد المنتج ورمزه الجمركي وبلد المنشأ وبلد الوجهة، ثم راجع التعرفة والمتطلبات الرسمية والشحن والتأمين. القواعد تختلف حسب السلعة والدول.';
    }
  }

  List<_BusinessResource> get _resources {
    switch (widget.type) {
      case AurenBusinessResourceType.factories:
        return const [
          _BusinessResource(
            name: 'Thomasnet',
            category: 'دليل صناعي',
            description: 'البحث عن مصنّعين وموردين وخدمات صناعية، خصوصاً في أمريكا الشمالية.',
            url: 'https://www.thomasnet.com/',
          ),
          _BusinessResource(
            name: 'Made-in-China.com',
            category: 'مصانع ومصنّعون',
            description: 'دليل لمصنّعين وموردين في الصين عبر قطاعات متعددة.',
            url: 'https://www.made-in-china.com/',
          ),
          _BusinessResource(
            name: 'Alibaba.com',
            category: 'تصنيع وتوريد',
            description: 'البحث عن المصانع والمصنّعين التعاقديين وتجار الجملة.',
            url: 'https://www.alibaba.com/',
          ),
          _BusinessResource(
            name: 'Global Sources',
            category: 'مصانع ومصنّعون',
            description: 'مصادر ومصنّعون، خصوصاً الإلكترونيات والمنتجات الاستهلاكية.',
            url: 'https://www.globalsources.com/',
          ),
          _BusinessResource(
            name: 'IndiaMART',
            category: 'دليل صناعي',
            description: 'دليل موردين ومصنّعين وشركات في الهند.',
            url: 'https://www.indiamart.com/',
          ),
          _BusinessResource(
            name: 'Kompass',
            category: 'دليل شركات',
            description: 'البحث عن شركات ومصنّعين حسب النشاط والدولة.',
            url: 'https://www.kompass.com/',
          ),
        ];
      case AurenBusinessResourceType.companies:
        return const [
          _BusinessResource(
            name: 'Kompass',
            category: 'دليل عالمي',
            description: 'البحث عن شركات وموردين حسب القطاع والموقع.',
            url: 'https://www.kompass.com/',
          ),
          _BusinessResource(
            name: 'Europages',
            category: 'دليل أعمال',
            description: 'دليل شركات وموردين، مع تركيز على الأسواق الأوروبية.',
            url: 'https://www.europages.com/',
          ),
          _BusinessResource(
            name: 'Dun & Bradstreet',
            category: 'معلومات أعمال',
            description: 'معلومات تجارية وبيانات شركات للمساعدة في التحقق التجاري؛ قد تتطلب بعض الخدمات اشتراكاً.',
            url: 'https://www.dnb.com/',
          ),
          _BusinessResource(
            name: 'Thomasnet',
            category: 'شركات صناعية',
            description: 'اكتشاف شركات ومصنّعين وموردين صناعيين في أمريكا الشمالية.',
            url: 'https://www.thomasnet.com/',
          ),
          _BusinessResource(
            name: 'TradeKey',
            category: 'تجارة بين الشركات',
            description: 'دليل تجاري للتواصل بين الشركات والبحث عن شركاء تجارة دولية.',
            url: 'https://www.tradekey.com/',
          ),
          _BusinessResource(
            name: 'African business directory',
            category: 'شركات أفريقية',
            description: 'ابدأ من دليل Kompass لتصفية الشركات حسب الدول والقطاعات الأفريقية المتاحة.',
            url: 'https://www.kompass.com/',
          ),
        ];
      case AurenBusinessResourceType.banks:
        return const [
          _BusinessResource(
            name: 'Afreximbank',
            category: 'تمويل التجارة الأفريقية',
            description: 'معلومات عن برامج دعم التجارة الأفريقية؛ ليست ضماناً للحصول على تمويل مباشر.',
            url: 'https://www.afreximbank.com/',
          ),
          _BusinessResource(
            name: 'IFC Trade Finance',
            category: 'تمويل التجارة',
            description: 'معلومات عن برامج تمويل التجارة عبر المؤسسات المالية المشاركة.',
            url: 'https://www.ifc.org/',
          ),
          _BusinessResource(
            name: 'EBRD Trade Facilitation Programme',
            category: 'ضمانات وتمويل تجارة',
            description: 'معلومات عن برنامج تسهيل التجارة وشبكة المؤسسات المالية المشاركة في الأسواق المؤهلة.',
            url: 'https://www.ebrd.com/',
          ),
          _BusinessResource(
            name: 'African Development Bank',
            category: 'تمويل تنموي',
            description: 'مصدر للتعرف على مبادرات تمويل التجارة والتنمية في أفريقيا وشروط كل برنامج.',
            url: 'https://www.afdb.org/',
          ),
          _BusinessResource(
            name: 'SWIFT',
            category: 'شبكة مراسلات مصرفية',
            description: 'معلومات عن شبكة المراسلات المالية؛ SWIFT ليست بنكاً ولا تمنح قرضاً للمستخدم.',
            url: 'https://www.swift.com/',
          ),
          _BusinessResource(
            name: 'البنك المركزي في بلدك',
            category: 'مصدر رسمي',
            description: 'تحقق من قائمة البنوك المرخصة وقواعد التحويلات والعملات وتمويل التجارة لدى الجهة الرقابية الرسمية.',
            url: 'https://www.bis.org/',
          ),
        ];
      case AurenBusinessResourceType.exportImport:
        return const [
          _BusinessResource(
            name: 'ITC Trade Map',
            category: 'الأسواق والطلب',
            description: 'استكشاف بيانات التجارة والأسواق والمنتجات المستوردة والمصدّرة.',
            url: 'https://www.trademap.org/',
          ),
          _BusinessResource(
            name: 'ITC Market Access Map',
            category: 'التعرفة والوصول للأسواق',
            description: 'البحث عن التعرفات الجمركية ومتطلبات الوصول إلى أسواق متعددة.',
            url: 'https://www.macmap.org/',
          ),
          _BusinessResource(
            name: 'EU Access2Markets',
            category: 'التصدير إلى الاتحاد الأوروبي',
            description: 'متطلبات الاستيراد والتعرفة والوثائق للمنتجات الداخلة إلى أسواق الاتحاد الأوروبي.',
            url: 'https://trade.ec.europa.eu/access-to-markets/en/home',
          ),
          _BusinessResource(
            name: 'WTO Tariff Data',
            category: 'بيانات التعرفة',
            description: 'بيانات ومراجع منظمة التجارة العالمية للتعرفة الجمركية.',
            url: 'https://www.wto.org/english/tratop_e/tariffs_e/tariff_data_e.htm',
          ),
          _BusinessResource(
            name: 'TradeKey — المشترون الدوليون',
            category: 'العثور على مشترين',
            description: 'دليل B2B للبحث عن شركات مهتمة بالتجارة الدولية؛ تحقق من هوية المشتري وطلبه قبل التفاوض.',
            url: 'https://www.tradekey.com/',
          ),
          _BusinessResource(
            name: 'Europages — المشترون والشركات',
            category: 'عملاء وشركاء تجاريون',
            description: 'استخدم دليل الشركات للعثور على جهات محتملة في الأسواق الأوروبية؛ الظهور في الدليل لا يثبت وجود طلب شراء.',
            url: 'https://www.europages.com/',
          ),
          _BusinessResource(
            name: 'ITC Export Potential Map',
            category: 'فرص وأسواق التصدير',
            description: 'استكشاف إمكانات التصدير والمنتجات والأسواق ذات الفرص المحتملة اعتماداً على بيانات التجارة.',
            url: 'https://exportpotential.intracen.org/',
          ),
          _BusinessResource(
            name: 'UN Comtrade',
            category: 'إحصاءات التجارة',
            description: 'بيانات إحصائية عن تجارة السلع بين الدول، وليست قائمة بمشترين جاهزين.',
            url: 'https://comtradeplus.un.org/',
          ),
          _BusinessResource(
            name: 'الجمارك السودانية',
            category: 'مصدر رسمي',
            description: 'للمعاملات المتعلقة بالسودان، تحقق من المتطلبات الحالية مباشرة من الجمارك والجهات المختصة.',
            url: 'https://customs.gov.sd/',
          ),
        ];
    }
  }

  List<String> get _checklist {
    switch (widget.type) {
      case AurenBusinessResourceType.factories:
        return const [
          'تحديد المنتج والمواصفات والكمية المطلوبة.',
          'طلب إثبات تسجيل المصنع وعنوانه القانوني.',
          'طلب عينة وشهادات الجودة والطاقة الإنتاجية.',
          'مقارنة السعر والحد الأدنى للطلب ومدة الإنتاج.',
          'تحديد شروط الفحص والدفع والشحن قبل التعاقد.',
        ];
      case AurenBusinessResourceType.companies:
        return const [
          'تحديد نوع الشريك: موزع أو وكيل أو تاجر جملة أو عميل.',
          'التحقق من التسجيل القانوني والعنوان ووسائل الاتصال.',
          'طلب مراجع تجارية والتحقق منها بشكل مستقل.',
          'الاتفاق كتابياً على النطاق والأسعار والمسؤوليات.',
        ];
      case AurenBusinessResourceType.banks:
        return const [
          'تحديد بلد الشركة والعملة وقيمة الصفقة.',
          'سؤال البنك عن الاعتماد المستندي والتحصيل والضمانات المتاحة.',
          'التحقق من الرسوم والمراسلين والقيود والتحويلات العابرة للحدود.',
          'طلب الشروط والأهلية مكتوبة من البنك أو الجهة الرسمية.',
        ];
      case AurenBusinessResourceType.exportImport:
        return const [
          'تحديد رمز HS الصحيح للمنتج وبلد المنشأ والوجهة.',
          'التحقق من التعرفة والتراخيص والمواصفات والقيود.',
          'تجهيز الفاتورة وقائمة التعبئة وشهادة المنشأ وأي شهادات مطلوبة.',
          'الحصول على عروض شحن وتأمين وتحديد شروط التسليم Incoterms.',
          'تأكيد المتطلبات النهائية مع الجمارك ومخلص مرخص قبل الشحن.',
        ];
    }
  }

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
    final rows = _resources.where((resource) {
      final searchable =
          '${resource.name} ${resource.category} ${resource.description}'.toLowerCase();
      return searchable.contains(query);
    }).toList();
    final done = _checklist.where(_completedChecklistItems.contains).length;

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_intro),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _queryController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'ابحث بالاسم أو النشاط أو نوع المصدر',
              border: const OutlineInputBorder(),
              suffixIcon: _queryController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'مسح البحث',
                      onPressed: () {
                        _queryController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text('المصادر: ${rows.length}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('لا توجد نتائج مطابقة. جرّب كلمة أخرى.'),
            ),
          ...rows.map(
            (resource) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.business_outlined),
                ),
                title: Text(resource.name),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${resource.category}\n${resource.description}'),
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _open(resource.url),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.route_outlined),
              title: const Text('متابعة صفقة تجارية'),
              subtitle: const Text(
                'نظّم مراحل الطلب والعروض والتحقق والتفاوض والشحن في مسار واحد.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AurenTradeDealScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text('قائمة التحقق', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('أكملت $done من ${_checklist.length} خطوات'),
          LinearProgressIndicator(
            value: _checklist.isEmpty ? 0 : done / _checklist.length,
          ),
          const SizedBox(height: 8),
          ..._checklist.map(
            (item) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _completedChecklistItems.contains(item),
              title: Text(item),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _completedChecklistItems.add(item);
                  } else {
                    _completedChecklistItems.remove(item);
                  }
                });
                _persistChecklist();
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'تنبيه: هذه مصادر بداية خارجية وليست نتائج تحقق آلي أو توصيات مضمونة. لا ترسل أموالاً أو مستندات حساسة قبل التحقق المستقل من الجهة وشروطها. تقدم AUREN هنا أدوات إرشادية ولا تنفذ معاملات مصرفية أو جمركية.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _BusinessResource {
  const _BusinessResource({
    required this.name,
    required this.category,
    required this.description,
    required this.url,
  });

  final String name;
  final String category;
  final String description;
  final String url;
}
