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

  static String performanceDataPrompt({required String sport, required List<String> measurements}) {
    final context = measurements.where((e) => e.trim().isNotEmpty).join('\n');
    return prompt(agent: 'performance', sport: sport, context: context, userQuestion: 'حلل القياسات المسجلة أعلاه فقط. لا تخلط مؤشرات مختلفة أو وحدات مختلفة. وضّح أحدث اتجاه، وما يمكن استنتاجه فعلاً، وما لا يمكن استنتاجه.');
  }
  static String scoutPrompt(String sport, String context) => prompt(agent: 'scout', sport: sport, context: context, userQuestion: 'أنشئ تقرير Scout يوضح نقاط القوة والمهارات والأدلة المتاحة والفجوات والفرص المناسبة.');

  static String athletePrompt({required String athleteName, required List<String> sports, required List<String> skills, required List<String> achievements}) {
    final sportText = sports.where((e) => e.trim().isNotEmpty).join(', ');
    final context = 'اللاعب: $athleteName\nالرياضات: $sportText\nالمهارات: ${skills.join(', ')}\nالإنجازات: ${achievements.join(', ')}';
    return prompt(agent: 'athlete', sport: sportText, context: context, userQuestion: 'حلل ملف الرياضي كما هو، واذكر نقاط القوة المحتملة والفجوات وما البيانات التي نحتاجها قبل أي استنتاج قوي. لا تعتبر اكتمال الملف دليلاً على مستوى اللاعب.');
  }

  static String whatIfPrompt({required String sport, required String scenario, required String context}) {
    return prompt(
      agent: 'analyst',
      sport: sport,
      context: context,
      userQuestion: 'حلل سيناريو What-If التالي: $scenario. اعرض الفرضيات والآثار المحتملة والبيانات الناقصة، ولا تقدمه كتوقع مؤكد أو حقيقة.',
    );
  }

  static String careerPrompt({required String sport, required String level, required String goals, required String evidence}) {
    return prompt(
      agent: 'opportunity',
      sport: sport,
      context: 'المستوى: $level\nالأهداف: $goals\nالأدلة المتاحة: $evidence',
      userQuestion: 'أنشئ Sports Career Map واقعي: مسارات محتملة، مهارات مطلوبة، أدلة ناقصة، وخطوات تالية. لا تضمن عقداً أو انتقالاً أو نجاحاً.',
    );
  }

  static String evidencePrompt({required String sport, required String evidence}) {
    return prompt(
      agent: 'truth',
      sport: sport,
      context: 'الأدلة التي قدمها المستخدم: $evidence',
      userQuestion: 'حلل Sports Evidence Locker: صنّف كل دليل كمعلومة ذات مصدر واضح أو ذاتية الإبلاغ أو تحتاج تحققاً، واقترح أسئلة التحقق. لا تمنح اعتماداً رسمياً.',
    );
  }

  static String athleteScoutPrompt({required String athleteName, required List<String> sports, required List<String> skills, required List<String> achievements, String level = '', String location = ''}) {
    final sportText = sports.where((e) => e.trim().isNotEmpty).join(', ');
    final context = 'اللاعب: $athleteName\nالرياضات: $sportText\nالمهارات: ${skills.join(', ')}\nالإنجازات: ${achievements.join(', ')}\nالمستوى: $level\nالموقع: $location';
    return prompt(agent: 'scout', sport: sportText, context: context, userQuestion: 'أنشئ تقرير Scout أولي يوضح نقاط القوة المدعومة بالملف، الفجوات، الأدلة المطلوبة، وأسئلة التحقق والفرص المحتملة. لا تخترع أندية أو بطولات أو أرقام أداء ولا تؤكد موهبة بشكل نهائي.');
  }
}