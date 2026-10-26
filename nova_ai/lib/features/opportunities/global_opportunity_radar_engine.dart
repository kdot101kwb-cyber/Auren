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
    final countryMatch = country == 'All countries' ||
        lead.country.toLowerCase().contains(country.toLowerCase()) ||
        (country == 'Sudan' && lead.country.toLowerCase().contains('sudan'));
    if (!countryMatch) return false;
    if (q.isEmpty) return true;
    final haystack = normalizeRadarText(
      '${lead.title} ${lead.description} ${lead.company} ${lead.category} ${lead.country} ${lead.language}',
    );
    return haystack.contains(q);
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
