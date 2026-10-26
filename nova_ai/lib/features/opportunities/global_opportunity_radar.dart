import 'package:flutter/foundation.dart';

@immutable
class GlobalOpportunity {
  final String id;
  final String title;
  final String category;
  final String summary;
  final String skills;
  final String languages;
  final String sourceName;
  final String url;
  final List<String> searchTerms;
  final String paymentNote;

  const GlobalOpportunity({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.skills,
    required this.languages,
    required this.sourceName,
    required this.url,
    required this.searchTerms,
    required this.paymentNote,
  });
}

/// Offline starter catalogue. Listings are entry points to official platforms,
/// not claims that a job is currently open or that a platform pays in every country.
const globalOpportunityCatalogue = <GlobalOpportunity>[
  GlobalOpportunity(
    id: 'upwork',
    title: 'خدمات حرة للشركات',
    category: 'عمل حر',
    summary: 'اعرض الكتابة والتحرير والبحث والتصميم والبرمجة وخدمات الأعمال على عملاء عالميين.',
    skills: 'كتابة، بحث، تصميم، برمجة، إدارة أعمال',
    languages: 'كل اللغات حسب العميل',
    sourceName: 'Upwork',
    url: 'https://www.upwork.com/',
    searchTerms: ['freelance', 'remote work', 'trabajo freelance', 'travail indépendant', 'freiberuflich', 'frilans', 'مستقل', 'عمل حر', 'وظائف عن بعد', 'フリーランス', '自由职业', 'स्वतंत्र काम'],
    paymentNote: 'تحقق من أهلية التسجيل والسحب إلى السودان قبل استثمار الوقت.',
  ),
  GlobalOpportunity(
    id: 'fiverr',
    title: 'بيع خدمات مصغّرة',
    category: 'عمل حر',
    summary: 'أنشئ عروضاً محددة مثل كتابة وصف المنتجات أو نصوص الفيديو أو الترجمة أو التصميم.',
    skills: 'تغليف الخدمة، كتابة عرض واضح، تسليم موثوق',
    languages: 'حسب الخدمة والعميل',
    sourceName: 'Fiverr',
    url: 'https://www.fiverr.com/',
    searchTerms: ['gig', 'microservice', 'servicios', 'services', 'خدمات مصغرة', 'بيع خدمة', 'gigs', 'servizi', '服务'],
    paymentNote: 'تحقق من دعم بلدك ووسيلة السحب والرسوم الحالية.',
  ),
  GlobalOpportunity(
    id: 'freelancer',
    title: 'المنافسة على مشاريع مستقلة',
    category: 'عمل حر',
    summary: 'ابحث عن مشاريع صغيرة وقدّم عرضاً مرتبطاً بمتطلبات العميل ونموذج عمل مناسب.',
    skills: 'تقديم عروض، كتابة، برمجة، تصميم، إدخال بيانات',
    languages: 'حسب المشروع',
    sourceName: 'Freelancer',
    url: 'https://www.freelancer.com/',
    searchTerms: ['freelance project', 'contest', 'proyecto', 'projet', 'مشروع مستقل', 'مسابقة تصميم', '竞赛'],
    paymentNote: 'افحص شروط البلد والسحب والتحقق من الهوية قبل قبول مشروع.',
  ),
  GlobalOpportunity(
    id: 'proz',
    title: 'ترجمة وتوطين المحتوى',
    category: 'لغات وترجمة',
    summary: 'قدّم خدمات ترجمة وتدقيق وتوطين للمواقع والمنتجات، مع مراجعة بشرية دقيقة.',
    skills: 'ترجمة، تدقيق، مصطلحات، توطين',
    languages: 'أزواج اللغات التي تتقنها',
    sourceName: 'ProZ',
    url: 'https://www.proz.com/',
    searchTerms: ['translation', 'localization', 'proofreading', 'traducción', 'traduction', 'ترجمة', 'توطين', 'التدقيق اللغوي', 'перевод', '翻译', 'अनुवाद'],
    paymentNote: 'راجع شروط العضوية وطريقة الدفع الخاصة بكل عميل أو عرض.',
  ),
  GlobalOpportunity(
    id: 'oneforma',
    title: 'مهام لغوية وبيانات للذكاء الاصطناعي',
    category: 'بيانات وذكاء اصطناعي',
    summary: 'تابع المشاريع المتاحة لتجميع البيانات أو تقييم النصوص أو تسجيل الصوت بحسب اللغة.',
    skills: 'اتباع التعليمات، لغة سليمة، انتباه للتفاصيل',
    languages: 'تختلف حسب المشروع واللهجة',
    sourceName: 'OneForma',
    url: 'https://www.oneforma.com/jobs/',
    searchTerms: ['data annotation', 'AI evaluation', 'speech', 'audio', 'transcription', 'تقييم الذكاء الاصطناعي', 'وسم البيانات', 'تفريغ صوتي', 'تسجيل صوت', 'données', 'anotación', '语音', 'डेटा लेबलिंग'],
    paymentNote: 'المشاريع والبلدان ووسائل الدفع تتغير؛ تأكد من الأهلية قبل أداء اختبار طويل.',
  ),
  GlobalOpportunity(
    id: 'telus-ai',
    title: 'تقييم نتائج البحث والذكاء الاصطناعي',
    category: 'بيانات وذكاء اصطناعي',
    summary: 'تحقق من فرص المجتمع الرقمي لتقييم البحث أو الإعلانات أو مخرجات الذكاء الاصطناعي.',
    skills: 'بحث، فهم سياق محلي، دقة، لغة',
    languages: 'مشاريع بلغات وأسواق محددة',
    sourceName: 'TELUS Digital AI Community',
    url: 'https://www.telusdigital.com/careers/ai-community',
    searchTerms: ['search evaluator', 'ads assessor', 'AI rater', 'قيم نتائج البحث', 'تقييم الإعلانات', 'مقيّم ذكاء اصطناعي', 'évaluateur', 'evaluador', '評価者'],
    paymentNote: 'لا تفترض توفر مشروع في السودان؛ افحص إعلان الوظيفة وبلد الإقامة المقبول.',
  ),
  GlobalOpportunity(
    id: 'crowdgen',
    title: 'مشاريع بيانات ومهام عن بعد',
    category: 'بيانات وذكاء اصطناعي',
    summary: 'ابحث عن مشاريع محددة للبيانات واللغة والصوت والتحقق من المحتوى.',
    skills: 'لغة، تصنيف، بحث، صوت، التزام بمعايير الجودة',
    languages: 'تختلف حسب المهمة',
    sourceName: 'CrowdGen by Appen',
    url: 'https://crowdgen.com/',
    searchTerms: ['data collection', 'language tasks', 'speech collection', 'جمع بيانات', 'مهام لغوية', 'جمع تسجيلات صوتية', 'recopilación de datos', 'collecte de données', 'データ収集'],
    paymentNote: 'تحقق من البلد ووسيلة الدفع والحد الأدنى للسحب لكل مشروع.',
  ),
  GlobalOpportunity(
    id: 'toloka',
    title: 'مهام رقمية قصيرة',
    category: 'مهام قصيرة',
    summary: 'افحص المهام المتاحة لتصنيف الصور أو مقارنة النتائج أو مراجعة البيانات.',
    skills: 'دقة، اتباع إرشادات، وقت قصير',
    languages: 'بحسب المهمة',
    sourceName: 'Toloka',
    url: 'https://toloka.ai/tolokers/',
    searchTerms: ['microtasks', 'label images', 'classification', 'مهام صغيرة', 'تصنيف صور', 'مقارنة نتائج', 'microtareas', 'petites tâches', '小任务'],
    paymentNote: 'تختلف إتاحة المهام والسحب حسب البلد والحساب؛ لا تستخدم VPN لتجاوز القيود.',
  ),
  GlobalOpportunity(
    id: 'github',
    title: 'مكافآت مساهمات البرمجيات المفتوحة',
    category: 'برمجة ومكافآت',
    summary: 'ابحث عن مستودعات موثوقة بها قضايا محددة ومكافآت معلنة؛ اقرأ شروط الجهة قبل العمل.',
    skills: 'برمجة، اختبار، توثيق، مراجعة كود',
    languages: 'لغات البرمجة ولغة المشروع',
    sourceName: 'GitHub',
    url: 'https://github.com/topics/bounty',
    searchTerms: ['open source bounty', 'bug bounty', 'coding', 'برمجة', 'مكافآت برمجية', 'إصلاح أخطاء', 'código abierto', 'logiciel libre', '开源'],
    paymentNote: 'وجود القضية لا يضمن المكافأة؛ تحقق من الجهة وشروط الاستحقاق وطريقة الدفع.',
  ),
  GlobalOpportunity(
    id: 'hackerone',
    title: 'برامج مكافآت اكتشاف الثغرات',
    category: 'برمجة ومكافآت',
    summary: 'تعلّم اختبار الأمان ضمن النطاق المصرّح به فقط، واقرأ سياسة البرنامج قبل أي اختبار.',
    skills: 'أمن تطبيقات، توثيق، اختبار مصرح',
    languages: 'حسب البرنامج',
    sourceName: 'HackerOne',
    url: 'https://www.hackerone.com/bug-bounty-programs',
    searchTerms: ['security research', 'vulnerability', 'bug bounty', 'أمن سيبراني', 'ثغرات أمنية', 'مكافأة ثغرة', 'seguridad', 'sécurité', '脆弱性'],
    paymentNote: 'لا تختبر أي نظام خارج النطاق المكتوب؛ المكافآت غير مضمونة والدفع يخضع لشروط البرنامج.',
  ),
  GlobalOpportunity(
    id: 'ko-fi',
    title: 'بيع منتجات رقمية ودعم الجمهور',
    category: 'منتجات رقمية',
    summary: 'أنشئ ملفات أصلية مثل قوالب أو أدلة أو موارد تعليمية، بعد التحقق من قدرة المنصة على الدفع لك.',
    skills: 'إنتاج رقمي، تسويق، خدمة جمهور',
    languages: 'لغة المنتج والجمهور',
    sourceName: 'Ko-fi',
    url: 'https://ko-fi.com/',
    searchTerms: ['digital products', 'creator support', 'templates', 'منتجات رقمية', 'قوالب', 'دعم المبدعين', 'productos digitales', 'produits numériques', 'デジタル商品'],
    paymentNote: 'تحقق من دعم مزود الدفع والبلد قبل إنشاء متجر أو الترويج للمنتج.',
  ),
  GlobalOpportunity(
    id: 'wellfound',
    title: 'وظائف عن بعد في الشركات الناشئة',
    category: 'وظائف عن بعد',
    summary: 'ابحث عن وظائف بعقود واضحة، وراجع بلد التوظيف ونوع العقد ومتطلبات الخبرة.',
    skills: 'تختلف حسب الوظيفة',
    languages: 'حسب الوصف الوظيفي',
    sourceName: 'Wellfound',
    url: 'https://wellfound.com/jobs',
    searchTerms: ['remote job', 'startup job', 'empleo remoto', 'emploi à distance', 'وظيفة عن بعد', 'عمل من المنزل', 'remote work', '远程工作', 'दूरस्थ नौकरी'],
    paymentNote: 'الوظيفة قد تكون مقيدة بدول معينة؛ تحقق من أهلية الإقامة والتوظيف والدفع.',
  ),
];

String normalizeRadarText(String value) {
  final lower = value.toLowerCase().trim();
  return lower
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[\u060C\u061B\u061F]'), '')
      .replaceAll(RegExp(r'[^a-z0-9\u00C0-\u024F\u0370-\u052F\u0600-\u06FF\u0900-\u097F\u4E00-\u9FFF]+'), ' ')
      .trim();
}

List<GlobalOpportunity> searchGlobalOpportunities({
  String query = '',
  String category = 'الكل',
  Iterable<String> savedIds = const [],
  bool savedOnly = false,
  Iterable<GlobalOpportunity> catalogue = globalOpportunityCatalogue,
}) {
  final normalizedQuery = normalizeRadarText(query);
  final saved = savedIds.toSet();
  final matches = catalogue.where((item) {
    if (category != 'الكل' && item.category != category) return false;
    if (savedOnly && !saved.contains(item.id)) return false;
    if (normalizedQuery.isEmpty) return true;
    final haystack = normalizeRadarText([
      item.title, item.category, item.summary, item.skills, item.languages,
      item.sourceName, ...item.searchTerms,
    ].join(' '));
    return haystack.contains(normalizedQuery);
  }).toList();
  matches.sort((a, b) => a.title.compareTo(b.title));
  return List<GlobalOpportunity>.unmodifiable(matches);
}

List<String> get globalOpportunityCategories => List<String>.unmodifiable([
  'الكل',
  ...{for (final item in globalOpportunityCatalogue) item.category}.toList()..sort(),
]);
