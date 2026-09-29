import 'education_resource_catalog.dart';

class EducationResourceRecommendation {
  final Map<String, String> resource;
  final int score;
  const EducationResourceRecommendation(this.resource, this.score);
}

class EducationResourceMatcher {
  static List<EducationResourceRecommendation> recommend({
    String subject = '', String language = '', String level = '', String preferredType = '', int limit = 6,
  }) {
    final query = subject.trim().toLowerCase();
    final lang = language.trim().toLowerCase();
    final type = preferredType.trim().toLowerCase();
    final results = <EducationResourceRecommendation>[];
    for (final resource in EducationResourceCatalog.resources) {
      final subjects = (resource['subjects'] ?? '').toLowerCase();
      final languages = (resource['languages'] ?? '').toLowerCase();
      final resourceType = (resource['type'] ?? '').toLowerCase();
      var score = 0;
      if (query.isNotEmpty && subjects.contains(query)) score += 8;
      if (lang.isNotEmpty && (languages.contains(lang) || languages.contains('many languages') || languages.contains('65+ languages'))) score += 6;
      if (type.isNotEmpty && resourceType.contains(type)) score += 4;
      if (level.isNotEmpty) score += 1;
      if (score > 0 || (query.isEmpty && lang.isEmpty && type.isEmpty)) results.add(EducationResourceRecommendation(resource, score));
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList(growable: false);
  }

  static String buildTutorPrompt({required String subject, String language = '', String level = ''}) {
    final recommendations = recommend(subject: subject, language: language, level: level, limit: 4);
    final sources = recommendations.map((item) => '${item.resource['name']} — ${item.resource['type']}').join('; ');
    return 'أريد تعلم $subject.'
        '${language.isEmpty ? '' : ' لغتي المفضلة: $language.'}'
        '${level.isEmpty ? '' : ' مستواي: $level.'}'
        ' استخدم هذه المصادر كمرجع عند الحاجة: $sources. لا تعِد نشر محتوى محمي؛ وجّهني للمصدر الأصلي، واشرح المفاهيم والتمارين بأسلوب يناسب مستواي.';
  }
}