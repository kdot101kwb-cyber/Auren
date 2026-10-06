import 'talent_sports_trust_service.dart';

enum TalentSportsAiRole {
  analyst,
  scout,
  performance,
  truth,
  athlete,
  video,
  opportunity,
  competition,
  multiSport,
}

class TalentSportsAiService {
  const TalentSportsAiService();

  String roleName(TalentSportsAiRole role) {
    switch (role) {
      case TalentSportsAiRole.analyst:
        return 'Sports Analyst AI';
      case TalentSportsAiRole.scout:
        return 'Scout AI';
      case TalentSportsAiRole.performance:
        return 'Performance AI';
      case TalentSportsAiRole.truth:
        return 'Sports Truth AI';
      case TalentSportsAiRole.athlete:
        return 'Athlete AI';
      case TalentSportsAiRole.video:
        return 'Video Analysis AI';
      case TalentSportsAiRole.opportunity:
        return 'Sports Opportunity AI';
      case TalentSportsAiRole.competition:
        return 'Competition AI';
      case TalentSportsAiRole.multiSport:
        return 'Multi-Sport AI';
    }
  }

  String buildMatchPrompt({
    required String title,
    required Map<String, String> details,
    required SportsTrustInfo trust,
    TalentSportsAiRole role = TalentSportsAiRole.analyst,
  }) {
    final facts = details.entries
        .where((e) => e.value.trim().isNotEmpty)
        .map((e) => '- ${e.key}: ${e.value.trim()}')
        .join('\n');

    return '''أنت ${roleName(role)} داخل AUREN.
حلل المباراة التالية باستخدام الحقائق المتاحة فقط.

المباراة: $title
المصدر: ${trust.sourceName}
مستوى الثقة: ${trust.trustLevel}

البيانات المتاحة:
$facts

قواعد صارمة:
1. لا تخترع نتيجة أو إحصائية أو إصابة أو تشكيلة أو حدثًا غير موجود في البيانات.
2. افصل بوضوح بين "المعلومة" و"التحليل" و"التوقع".
3. إذا كانت البيانات ناقصة، قل إن البيانات غير كافية بدل ملء الفراغات.
4. لا تقدم المصدر غير الرسمي كأنه بيان رسمي.
5. لا تدّع أن التحليل يمثل حكمًا رسميًا من اتحاد أو نادٍ أو بطولة.

أعطني تحليلًا مختصرًا ومفيدًا للمستخدم.''';
  }

  String buildAthletePrompt({
    required String athleteName,
    required List<String> sports,
    required List<String> skills,
    required List<String> achievements,
    TalentSportsAiRole role = TalentSportsAiRole.athlete,
  }) {
    return '''أنت ${roleName(role)} في AUREN.
الرياضي: $athleteName
الرياضات: ${sports.join(', ')}
المهارات المسجلة: ${skills.join(', ')}
الإنجازات المسجلة: ${achievements.join(', ')}

حلل البيانات المسجلة فقط. لا تعتبر اكتمال الملف دليلًا على مستوى الأداء الحقيقي، ولا تصنع إنجازات أو إحصائيات غير موجودة.
حدد:
- نقاط القوة الظاهرة من البيانات
- المعلومات الناقصة
- الخطوة التالية المقترحة
- ما يحتاج إلى دليل أو مصدر موثوق.''';
  }
}
