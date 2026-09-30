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
      final subjectTokens = query
          .split(RegExp(r'[^a-zA-Z0-9\\u0600-\\u06FF]+'))
          .where((token) => token.length >= 2)
          .toList();
      final subjectHit = subjectTokens.any((token) => subjects.contains(token));
      if (query.isNotEmpty && subjects.contains(query)) {
        score += 10;
      } else if (subjectHit) {
        score += 6;
      }

      final languageAliases = <String, List<String>>{
        'العربية': ['arabic'],
        'English': ['english'],
        'Français': ['french', 'français'],
        'Español': ['spanish', 'español'],
        'Português': ['portuguese', 'português'],
        'Deutsch': ['german', 'deutsch'],
        'Italiano': ['italian', 'italiano'],
        'Türkçe': ['turkish', 'türkçe'],
        '中文': ['mandarin', 'chinese', '中文'],
        '日本語': ['japanese', '日本語'],
        '한국어': ['korean', '한국어'],
        'हिन्दी': ['hindi', 'हिन्दी'],
        'বাংলা': ['bengali', 'বাংলা'],
        'اردو': ['urdu', 'اردو'],
        'فارسی': ['farsi', 'persian', 'فارسی'],
      };
      final aliases = languageAliases[language] ?? [lang];
      final languageHit = aliases.any(languages.contains);
      if (lang.isNotEmpty && (languageHit || languages.contains('many languages') || languages.contains('65+ languages'))) {
        score += languageHit ? 8 : 5;
      }

      if (type.isNotEmpty && resourceType.contains(type)) score += 5;

      final levelBonus = switch (level.toLowerCase()) {
        'beginner' => resourceType.contains('practice') || resourceType.contains('videos') ? 2 : 1,
        'elementary' => resourceType.contains('practice') || resourceType.contains('videos') ? 2 : 1,
        'intermediate' => resourceType.contains('courses') || resourceType.contains('textbooks') ? 2 : 1,
        'upper intermediate' => resourceType.contains('courses') || resourceType.contains('books') ? 2 : 1,
        'advanced' => resourceType.contains('courses') || resourceType.contains('research') ? 2 : 1,
        _ => 0,
      };
      score += levelBonus;
      if (score > 0 || (query.isEmpty && lang.isEmpty && type.isEmpty)) results.add(EducationResourceRecommendation(resource, score));
    }
    results.sort((a, b) => b.score.compareTo(a.score));

    // Prefer a useful mix of learning modes instead of returning several
    // resources that serve the same role.
    final selected = <EducationResourceRecommendation>[];
    final usedRoles = <String>{};
    String roleOf(String resourceType) {
      final t = resourceType.toLowerCase();
      if (t.contains('simulation')) return 'simulation';
      if (t.contains('video')) return 'video';
      if (t.contains('practice') || t.contains('lab')) return 'practice';
      if (t.contains('book') || t.contains('textbook')) return 'book';
      if (t.contains('course') || t.contains('lecture')) return 'course';
      if (t.contains('research')) return 'research';
      return 'other';
    }

    for (final item in results) {
      final role = roleOf(item.resource['type'] ?? '');
      if (usedRoles.add(role)) selected.add(item);
      if (selected.length == limit) break;
    }

    // If the catalog cannot fill every learning mode, fill the remaining
    // slots with the highest-scoring resources.
    if (selected.length < limit) {
      for (final item in results) {
        if (!selected.contains(item)) selected.add(item);
        if (selected.length == limit) break;
      }
    }
    return selected.toList(growable: false);
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