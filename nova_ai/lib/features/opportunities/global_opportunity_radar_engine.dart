import 'dart:convert';

/// A normalized public listing. Availability, eligibility and pay are never
/// inferred from a listing alone.
class GlobalOpportunityLead {
  final String id;
  final String title;
  final String description;
  final String company;
  final String country;
  final String category;
  final String source;
  final String url;
  final String language;
  final String salary;
  final bool remote;
  final DateTime? publishedAt;

  const GlobalOpportunityLead({
    required this.id,
    required this.title,
    required this.description,
    required this.company,
    required this.country,
    required this.category,
    required this.source,
    required this.url,
    required this.language,
    required this.salary,
    required this.remote,
    this.publishedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'description': description,
    'company': company, 'country': country, 'category': category,
    'source': source, 'url': url, 'language': language,
    'salary': salary, 'remote': remote,
    'publishedAt': publishedAt?.toIso8601String(),
  };

  factory GlobalOpportunityLead.fromJson(Map<String, dynamic> json) =>
      GlobalOpportunityLead(
        id: _s(json['id']), title: _s(json['title']),
        description: _s(json['description']), company: _s(json['company']),
        country: _s(json['country']), category: _s(json['category']),
        source: _s(json['source']), url: _s(json['url']),
        language: _s(json['language']), salary: _s(json['salary']),
        remote: json['remote'] == true,
        publishedAt: DateTime.tryParse(_s(json['publishedAt'])),
      );

  static String _s(Object? value) => value?.toString() ?? '';
}

String normalizeRadarText(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Localized search terms are query expansions, not translations of arbitrary
/// user text. The original query is always retained.
const Map<String, List<String>> radarLocalizedTerms = {
  'work': ['work', 'job', 'trabajo', 'empleo', 'travail', 'emploi', 'arbeit', 'lavoro', 'trabalho', 'عمل', 'وظيفة', 'работа', 'काम', 'kazi', '工作', '仕事'],
  'freelance': ['freelance', 'freelancer', 'independent contractor', 'عمل حر', 'مستقل', 'autónomo', 'freelanceur', 'freiberuflich', 'freelancer', '프리랜서'],
  'translation': ['translation', 'localization', 'ترجمة', 'تعريب', 'traducción', 'traduction', 'übersetzung', 'traduzione', 'tradução', '翻译', '翻訳'],
  'data': ['data annotation', 'data labeling', 'AI evaluation', 'تقييم الذكاء الاصطناعي', 'وسم البيانات', 'anotación de datos', 'annotation de données', 'Datenannotation', 'etiquetagem de dados'],
  'content': ['content writing', 'copywriting', 'كتابة المحتوى', 'كتابة إعلانية', 'redacción', 'rédaction', 'texten', 'scrittura', 'redação'],
  'languages': [
    'remote', 'job', 'freelance', 'работа', 'удалённая работа', 'перевод',
    '일자리', '원격 근무', '프리랜서', '번역',
    'lavoro', 'lavoro da remoto', 'traduzione',
    'pekerjaan jarak jauh', 'freelance', 'penerjemahan',
    'uzaktan iş', 'iş ilanı', 'çeviri',
    'দূরবর্তী কাজ', 'চাকরি', 'অনুবাদ',
    'việc làm từ xa', 'việc làm', 'dịch thuật',
    'งานระยะไกล', 'งาน', 'แปลภาษา',
    'وظائف عن بعد', 'ترجمة', 'работа', 'काम',
    'praca zdalna', 'tłumaczenie',
    'remote werk', 'vertaling',
    'trabaho', 'malayuang trabaho', 'pagsasalin',
  ],
};

List<String> expandRadarQueries(String query, {String category = 'All'}) {
  final q = query.trim();
  final key = switch (category) {
    'Work' => 'work',
    'Freelance' => 'freelance',
    'Translation' => 'translation',
    'AI & Data' => 'data',
    'Content' => 'content',
    _ => '',
  };
  final terms = <String>{if (q.isNotEmpty) q};
  if (key.isNotEmpty) terms.addAll(radarLocalizedTerms[key]!);
  if (q.isEmpty && key.isEmpty) {
    terms.addAll(radarLocalizedTerms['work']!);
    terms.addAll(radarLocalizedTerms['freelance']!);
    terms.addAll(radarLocalizedTerms['translation']!);
    terms.addAll(radarLocalizedTerms['data']!);
    terms.addAll(radarLocalizedTerms['content']!);
  }
  return terms.where((s) => s.trim().isNotEmpty).take(18).toList();
}

List<GlobalOpportunityLead> rankGlobalLeads(
  Iterable<GlobalOpportunityLead> leads, {
  String query = '',
  String country = 'All countries',
  String region = 'Worldwide',
}) {
  final q = normalizeRadarText(query);
  final filtered = leads.where((lead) {
    final place = lead.country.toLowerCase();
    final worldwide = RegExp(r'worldwide|anywhere|global|all countries|worldwide eligibility not stated').hasMatch(place);
    final countryMatch = country == 'All countries' || place.contains(country.toLowerCase()) || (country == 'Sudan' && worldwide);
    if (!countryMatch) return false;
    final regionMatch = switch (region) {
      'Worldwide' => true,
      'Africa' => worldwide || RegExp(r'africa|kenya|nigeria|south africa|egypt|sudan|ghana|morocco|uganda|tanzania').hasMatch(place),
      'Europe' => worldwide || RegExp(r'europe|germany|france|spain|uk|united kingdom|ireland|poland|netherlands|portugal|italy').hasMatch(place),
      'Asia' => worldwide || RegExp(r'asia|india|pakistan|japan|china|singapore|philippines|indonesia|uae|emirates').hasMatch(place),
      'Americas' => worldwide || RegExp(r'america|united states|usa|canada|brazil|mexico|argentina|colombia').hasMatch(place),
      _ => true,
    };
    if (!regionMatch) return false;
    if (q.isEmpty) return true;
    final haystack = normalizeRadarText(
      '${lead.title} ${lead.description} ${lead.company} ${lead.category} ${lead.country} ${lead.language}',
    );
    final tokens = q.split(' ').where((token) => token.length > 2).toList();
    return tokens.isEmpty || tokens.any(haystack.contains);
  }).toList();
  int score(GlobalOpportunityLead lead) {
    var value = lead.remote ? 10 : 0;
    if (lead.url.startsWith('https://')) value += 5;
    if (lead.salary.trim().isNotEmpty) value += 2;
    if (lead.publishedAt != null) {
      final age = DateTime.now().difference(lead.publishedAt!).inDays;
      if (age >= 0 && age <= 14) value += 4;
      if (age < 0) value -= 3;
    }
    if (region == 'Africa' && RegExp(r'africa|kenya|nigeria|south africa|egypt|sudan|remote', caseSensitive: false).hasMatch(lead.country)) value += 3;
    if (region == 'Europe' && RegExp(r'europe|germany|france|spain|uk|united kingdom|remote', caseSensitive: false).hasMatch(lead.country)) value += 3;
    if (region == 'Asia' && RegExp(r'asia|india|pakistan|japan|china|remote', caseSensitive: false).hasMatch(lead.country)) value += 3;
    return value;
  }
  filtered.sort((a, b) {
    final byScore = score(b).compareTo(score(a));
    if (byScore != 0) return byScore;
    return (b.publishedAt?.millisecondsSinceEpoch ?? 0)
        .compareTo(a.publishedAt?.millisecondsSinceEpoch ?? 0);
  });
  return List.unmodifiable(filtered);
}

/// A locally prepared starter pack for reviewing an opportunity.
/// This does not submit an application or claim that the sample is client-ready.
class OpportunityWorkPack {
  final String summary;
  final String fitAssessment;
  final String preparationPlan;
  final String proposalDraft;
  final String sampleTask;
  final List<String> checksBeforeApplying;

  const OpportunityWorkPack({
    required this.summary,
    required this.fitAssessment,
    required this.preparationPlan,
    required this.proposalDraft,
    required this.sampleTask,
    required this.checksBeforeApplying,
  });

  String toPlainText() => [
    'NOVA — ملف تحضير فرصة',
    '',
    'الفرصة: $summary',
    '',
    'تقييم مبدئي: $fitAssessment',
    '',
    'خطة التحضير:',
    preparationPlan,
    '',
    'مسودة عرض قابلة للتعديل:',
    proposalDraft,
    '',
    'عينة عمل مقترحة (تحتاج مراجعة):',
    sampleTask,
    '',
    'قبل التقديم:',
    ...checksBeforeApplying.map((item) => '- $item'),
  ].join('\n');
}

OpportunityWorkPack prepareOpportunityWorkPack(GlobalOpportunityLead lead) {
  final text = normalizeRadarText('${lead.title} ${lead.description} ${lead.category}');
  final tasks = <String>[];
  String sample;
  String proposalFocus;
  if (RegExp(r'translat|locali[sz]|transcri|subtitl|caption|language|ترجم|تفريغ').hasMatch(text)) {
    tasks.addAll([
      'استخراج المطلوب واللغة واللهجة والتنسيق من وصف العميل.',
      'تجهيز عينة قصيرة للمراجعة مع الحفاظ على المعنى وعدم اختلاق محتوى.',
      'مراجعة المصطلحات والأسماء ثم مقارنة الناتج بالنص الأصلي.',
    ]);
    sample = 'نموذج توضيحي فقط — النص الأصلي: “Please send the updated file today.”\\nالترجمة العربية: “يرجى إرسال الملف المحدّث اليوم.”\\nملاحظة المراجعة: تأكد من السياق والنبرة والمصطلحات المطلوبة قبل اعتماد أي ترجمة فعلية.';
    proposalFocus = 'translation, transcription, or localization support';
  } else if (RegExp(r'content|copywrit|blog|article|social media|script|writing|كتابة|محتوى').hasMatch(text)) {
    tasks.addAll([
      'تحديد الجمهور والهدف والنبرة المطلوبة من وصف المهمة.',
      'كتابة مسودة واحدة قصيرة ونموذج بديل للعنوان أو الافتتاحية.',
      'مراجعة الحقائق واللغة وحقوق الصور/الموسيقى قبل التسليم.',
    ]);
    sample = 'نموذج محتوى تجريبي — الموضوع: تقليل العمل المتكرر باستخدام أدوات رقمية.\\nالعنوان: خلّي وقتك للشغل المهم.\\nالنص: ابدأ بتحديد مهمة متكررة واحدة، جرّب أداة مجانية لتنظيمها، ثم راجع النتيجة بنفسك قبل الاعتماد عليها.\\nالدعوة: ما أول مهمة تتمنى تختصر وقتها؟\\nملاحظة: هذا مثال عام وليس موجهاً لعلامة العميل؛ عدّله وفق موجز العميل.';
    proposalFocus = 'content writing and short-form script preparation';
  } else if (RegExp(r'data annot|data label|ai evaluat|rating|categor|spreadsheet|research|وسم بيانات|تقييم').hasMatch(text)) {
    tasks.addAll([
      'استخراج قواعد التصنيف ومعايير الجودة من وصف المهمة.',
      'إنشاء جدول تجريبي صغير ببيانات عامة أو اصطناعية فقط.',
      'مراجعة العينة يدوياً وقياس الأخطاء قبل توسيع العمل.',
    ]);
    sample = 'عينة بيانات اصطناعية فقط (ليست بيانات عميل):\\nitem_001 | النص: “التوصيل وصل سريعاً” | التصنيف: positive | السبب: يمدح سرعة التوصيل\\nitem_002 | النص: “الطلب لم يصل” | التصنيف: negative | السبب: مشكلة في استلام الطلب\\nitem_003 | النص: “الخدمة عادية” | التصنيف: neutral | السبب: لا يظهر مدح أو ذم واضح\\nitem_004 | النص: “الدعم حل المشكلة” | التصنيف: positive | السبب: يذكر حلاً ناجحاً\\nitem_005 | النص: “وصل منتج مختلف” | التصنيف: negative | السبب: عدم مطابقة المنتج';
    proposalFocus = 'structured data review and AI-assisted evaluation';
  } else if (RegExp(r'automat|workflow|no code|developer|software|website|app build|program|برمجة|تطبيق').hasMatch(text)) {
    tasks.addAll([
      'تحويل المطلوب إلى قائمة متطلبات صغيرة قابلة للاختبار.',
      'اقتراح أبسط نموذج أولي مجاني يناسب المهمة قبل بناء حل كامل.',
      'كتابة اختبارات أساسية وتوثيق ما لم يتم اختباره بعد.',
    ]);
    sample = 'نموذج سير عمل أولي: 1) استقبال الطلب. 2) التحقق من الحقول المطلوبة. 3) حفظ نسخة محلية. 4) عرض النتيجة للمراجعة البشرية. 5) تنفيذ الإرسال فقط بعد الموافقة.\\nاختبارات مقترحة: طلب مكتمل، حقل ناقص، تكرار الطلب، وفشل الشبكة. هذا مخطط أولي وليس تكاملاً منفذاً.';
    proposalFocus = 'a small, testable automation or prototype';
  } else {
    tasks.addAll([
      'تلخيص المطلوب والمخرجات والموعد النهائي من إعلان الفرصة.',
      'تقسيم المهمة إلى أجزاء يمكن تجهيزها بأدوات مجانية.',
      'إعداد عينة صغيرة لا تكشف معلومات خاصة قبل الالتزام بالمهمة كاملة.',
    ]);
    sample = 'ملخص بداية العمل: المطلوب الدقيق غير محسوم من عنوان الإعلان وحده. استخرج 3 مخرجات متوقعة من الوصف، واكتب سؤالاً واحداً عن معيار القبول قبل بناء عينة مرتبطة بالمهمة.';
    proposalFocus = 'a small, clearly scoped first deliverable';
  }

  final company = lead.company.trim().isEmpty ? 'your team' : lead.company.trim();
  final fit = lead.salary.trim().isEmpty
      ? 'مبدئي فقط: الأجر غير ظاهر في بيانات الرادار، والأهلية من السودان وطريقة الدفع غير مؤكدتين.'
      : 'مبدئي فقط: الأجر مذكور في الإعلان، لكن الأهلية من السودان وطريقة الدفع وشروط المهمة تحتاج تحققاً من المصدر.';
  final proposal = 'Hello $company,\n\nI am interested in your ${lead.title} opportunity. I can start by preparing a small sample focused on $proposalFocus, then align the work with your instructions and quality requirements.\n\nBefore starting, I would like to confirm the scope, deadline, acceptance criteria, permitted use of AI tools, and payment method. I will not claim experience or completed work that I cannot substantiate.\n\nThank you for considering my proposal.';
  final checks = <String>[
    'هل يسمح الإعلان بالتقديم من السودان؟ كلمة Remote أو Worldwide وحدها لا تكفي.',
    'هل الأجر وطريقة الدفع والسحب متاحة فعلاً للمستخدم في السودان؟',
    'هل توجد رسوم مقدّمة أو طلب لإيداع مال؟ لا تدفع رسوماً للبدء.',
    'هل يسمح العميل باستخدام أدوات الذكاء الاصطناعي لهذه المهمة؟',
    'هل الشركة ورابط التقديم أصليان، وما هي المخرجات والموعد وشروط القبول؟',
  ];
  return OpportunityWorkPack(
    summary: '${lead.title} — $company — ${lead.source}',
    fitAssessment: fit,
    preparationPlan: tasks.map((item) => '- $item').join('\n'),
    proposalDraft: proposal,
    sampleTask: sample,
    checksBeforeApplying: List.unmodifiable(checks),
  );
}

/// Explain which parts NOVA may be able to prepare for a lead.
/// This is a suggested workflow, not a claim that NOVA can autonomously perform
/// paid work or submit an application.
List<String> novaExecutionPlanForLead(GlobalOpportunityLead lead) {
  final text = normalizeRadarText('${lead.title} ${lead.description} ${lead.category}');
  final steps = <String>[];
  if (RegExp(r'translat|locali[sz]|transcri|subtitl|caption|language|ترجم|تفريغ').hasMatch(text)) {
    steps.add('NOVA يمكنه تجهيز مسودة ترجمة أو تفريغ ومراجعتها معك قبل التسليم.');
  }
  if (RegExp(r'content|copywrit|blog|article|social media|script|writing|كتابة|محتوى').hasMatch(text)) {
    steps.add('NOVA يمكنه إعداد مسودة محتوى أو نص منشور ونماذج أولية.');
  }
  if (RegExp(r'data annot|data label|ai evaluat|rating|categor|spreadsheet|research|وسم بيانات|تقييم').hasMatch(text)) {
    steps.add('NOVA يمكنه تنظيم البيانات أو إعداد عينة عمل، إذا كانت المهمة تسمح باستخدام أدوات AI.');
  }
  if (RegExp(r'automat|workflow|no code|developer|software|website|app build|program|برمجة|تطبيق').hasMatch(text)) {
    steps.add('NOVA يمكنه تحليل المطلوب واقتراح أو تجهيز نموذج أولي تقني للاختبار.');
  }
  if (steps.isEmpty) {
    steps.add('NOVA يقدر يحلل الوصف ويجهّز مسودة أو خطة عمل بعد التأكد من متطلبات المهمة.');
  }
  steps.add('قبل التنفيذ: تحقق من السماح باستخدام الذكاء الاصطناعي، والمهارات المطلوبة، والأجر، وأهلية السودان. التقديم والتسليم والدفع ليست تلقائية.');
  return List.unmodifiable(steps);
}

/// Conservative checks for what the public listing actually tells us.
/// These checks never infer Sudan eligibility or a payout method from "remote".
List<String> opportunityVerificationWarnings(GlobalOpportunityLead lead) {
  final warnings = <String>[];
  final place = normalizeRadarText(lead.country);
  final statesSudan = place.contains('sudan');
  final statesWorldwide = RegExp(r'worldwide|anywhere|global|all countries').hasMatch(place);
  if (!statesSudan && !statesWorldwide) {
    warnings.add('قبول المتقدمين من السودان غير مؤكد؛ راجع شروط البلد في المصدر.');
  } else if (statesWorldwide) {
    warnings.add('وصف Worldwide لا يضمن قبول السودان؛ تحقق من شروط التقديم.');
  }
  if (lead.salary.trim().isEmpty) {
    warnings.add('الأجر غير مذكور في بيانات الرادار؛ تحقق منه قبل التقديم.');
  }
  warnings.add('وسيلة الدفع غير موثقة هنا؛ تأكد من PayPal أو USDT أو البديل المتاح قبل بدء العمل.');
  return List.unmodifiable(warnings);
}

/// Parses the public Himalayas Jobs API response while retaining its
/// required attribution and application-link semantics.
/// Parses Jobicy's public API listing while keeping the canonical listing URL.
GlobalOpportunityLead? parseJobicyLead(Map<String, dynamic> json) {
  final title = (json['jobTitle'] ?? '').toString().trim();
  final url = (json['url'] ?? '').toString().trim();
  final uri = Uri.tryParse(url);
  if (title.isEmpty || uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    return null;
  }
  final minSalary = json['salaryMin'];
  final maxSalary = json['salaryMax'];
  final currency = (json['salaryCurrency'] ?? '').toString().trim();
  final period = (json['salaryPeriod'] ?? '').toString().trim();
  final salary = minSalary != null && maxSalary != null
      ? '${currency.isEmpty ? '' : '$currency '}$minSalary–$maxSalary${period.isEmpty ? '' : ' / $period'}'
      : '';
  final pubDate = DateTime.tryParse((json['pubDate'] ?? '').toString());
  return GlobalOpportunityLead(
    id: 'jobicy:${json['id'] ?? url}',
    title: title,
    description: _stripHtml((json['jobDescription'] ?? json['jobExcerpt'] ?? '').toString()),
    company: (json['companyName'] ?? '').toString(),
    country: (json['jobGeo'] ?? 'Location eligibility not stated').toString(),
    category: (json['jobIndustry'] ?? json['jobType'] ?? '').toString(),
    source: 'Jobicy',
    url: url,
    language: (json['jobType'] ?? 'Not stated').toString(),
    salary: salary,
    remote: true,
    publishedAt: pubDate,
  );
}

GlobalOpportunityLead? parseHimalayasLead(Map<String, dynamic> json) {
  final title = (json['title'] ?? '').toString().trim();
  final url = (json['applicationLink'] ?? '').toString().trim();
  if (title.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  final restrictions = json['locationRestrictions'];
  final country = restrictions is List && restrictions.isNotEmpty
      ? restrictions.map((item) => item.toString()).join(', ')
      : 'Worldwide (no location restrictions listed)';
  final minSalary = json['minSalary'];
  final maxSalary = json['maxSalary'];
  final currency = (json['currency'] ?? '').toString().trim();
  final period = (json['salaryPeriod'] ?? 'annual').toString().trim();
  final salary = minSalary != null && maxSalary != null
      ? '${currency.isEmpty ? '' : '$currency '}$minSalary–$maxSalary / $period'
      : '';
  final categories = json['categories'] is List
      ? (json['categories'] as List).map((item) => item.toString()).join(', ')
      : '';
  final publishedAt = json['pubDate'] is num
      ? DateTime.fromMillisecondsSinceEpoch((json['pubDate'] as num).toInt() * 1000, isUtc: true)
      : DateTime.tryParse((json['pubDate'] ?? '').toString());
  return GlobalOpportunityLead(
    id: 'himalayas:${json['guid'] ?? url}',
    title: title,
    description: _stripHtml((json['description'] ?? json['excerpt'] ?? '').toString()),
    company: (json['companyName'] ?? '').toString(),
    country: country,
    category: categories,
    source: 'Himalayas · himalayas.app',
    url: url,
    language: (json['employmentType'] ?? 'Not stated').toString(),
    salary: salary,
    remote: true,
    publishedAt: publishedAt,
  );
}

GlobalOpportunityLead? parseRemotiveLead(Map<String, dynamic> json) {
  final title = (json['title'] ?? '').toString().trim();
  final url = (json['url'] ?? '').toString().trim();
  if (title.isEmpty || !url.startsWith('https://')) return null;
  return GlobalOpportunityLead(
    id: 'remotive:${json['id'] ?? url}',
    title: title,
    description: _stripHtml((json['description'] ?? '').toString()),
    company: (json['company_name'] ?? '').toString(),
    country: (json['candidate_required_location'] ?? 'Worldwide eligibility not stated').toString(),
    category: (json['category'] ?? '').toString(),
    source: 'Remotive',
    url: url,
    language: (json['job_type'] ?? 'Not stated').toString(),
    salary: (json['salary'] ?? '').toString(),
    remote: true,
    publishedAt: DateTime.tryParse((json['publication_date'] ?? '').toString()),
  );
}

GlobalOpportunityLead? parseArbeitnowLead(Map<String, dynamic> json) {
  final title = (json['title'] ?? '').toString().trim();
  final url = (json['url'] ?? '').toString().trim();
  if (title.isEmpty || !url.startsWith('https://')) return null;
  final tags = (json['tags'] is List ? json['tags'] as List : const [])
      .map((e) => e.toString()).join(', ');
  return GlobalOpportunityLead(
    id: 'arbeitnow:${json['slug'] ?? url}',
    title: title,
    description: _stripHtml((json['description'] ?? '').toString()),
    company: (json['company_name'] ?? '').toString(),
    country: (json['location'] ?? 'Country not stated').toString(),
    category: tags,
    source: 'Arbeitnow',
    url: url,
    language: 'Not stated by source',
    salary: '',
    remote: json['remote'] == true,
    publishedAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
  );
}

String _stripHtml(String value) => value
    .replaceAll(RegExp(r'<[^>]*>'), ' ')
    .replaceAll(RegExp(r'&nbsp;|&#160;'), ' ')
    .replaceAll(RegExp(r'&amp;'), '&')
    .replaceAll(RegExp(r'&quot;'), '"')
    .replaceAll(RegExp(r'&#39;|&apos;'), "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

List<GlobalOpportunityLead> decodeSavedRadarLeads(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final data = jsonDecode(raw);
    if (data is! List) return const [];
    return data.whereType<Map>().map((row) =>
      GlobalOpportunityLead.fromJson(Map<String, dynamic>.from(row))).toList();
  } catch (_) {
    return const [];
  }
}
