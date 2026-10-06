class AurenSportsAiService {
  static const supportedAgents = <String, String>{
    'analyst': 'Sports Analyst AI',
    'scout': 'Scout AI',
    'performance': 'Performance AI',
    'truth': 'Sports Truth AI',
    'athlete': 'Athlete AI',
    'video': 'Video Analysis AI',
    'opportunity': 'Transfer & Opportunity AI',
    'competition': 'Competition AI',
    'multi_sport': 'Multi-Sport AI',
  };

  static String prompt({required String agent, required String sport, String context = '', String userQuestion = ''}) {
    final role = supportedAgents[agent] ?? 'Sports Analyst AI';
    final sportText = sport.trim().isEmpty ? 'الرياضة غير محددة' : sport.trim();
    return '''أنت $role داخل AUREN Sports AI.
الرياضة: $sportText.
مهمتك تقديم تحليل رياضي متخصص ومفيد، لكن لا تخترع بيانات أو نتائج أو إصابات أو مصادر.
استخدم البيانات التي يرسلها المستخدم أو المتاحة في السياق فقط.
إذا كانت معلومة غير متوفرة، قل إنها غير متوفرة بوضوح.
فرّق دائماً بين: حقيقة موثقة، بيانات مصدر رياضي، تحليل احتمالي، ورأي.
لا تقدم توقعاً على أنه نتيجة مؤكدة، ولا تشخّص حالة طبية.
${context.trim().isEmpty ? '' : 'السياق المتاح:\n$context\n'}
${userQuestion.trim().isEmpty ? '' : 'سؤال المستخدم:\n$userQuestion\n'}
ابدأ بإجابة عملية ومختصرة، ثم اذكر أهم الأدلة والقيود.''';
  }

  static String matchPrompt(String title, String sport, String context) => prompt(agent: 'analyst', sport: sport, context: context, userQuestion: 'حلل المباراة $title من البيانات المتاحة فقط، واشرح عوامل الأداء والتغير في المباراة دون اختراع إحصائيات.');
  static String performancePrompt(String sport, String context) => prompt(agent: 'performance', sport: sport, context: context, userQuestion: 'راجع قياسات أدائي، استخرج الاتجاهات ونقاط القوة والفجوات واقترح خطوات تدريب عامة قابلة للمتابعة.');
  static String scoutPrompt(String sport, String context) => prompt(agent: 'scout', sport: sport, context: context, userQuestion: 'أنشئ تقرير Scout يوضح نقاط القوة والمهارات والأدلة المتاحة والفجوات والفرص المناسبة.');
}