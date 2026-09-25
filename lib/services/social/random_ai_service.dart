class AurenRandomAiService {
  static const starters = <String>[
    'شنو أكثر حاجة مهتم بيها هسي؟',
    'لو عندك فرصة تتعلم مهارة جديدة، تختار شنو؟',
    'شنو المشروع أو الهدف البتشتغل عليه حالياً؟',
    'شنو أكتر بلد أو ثقافة نفسك تتعرف عليها؟',
    'خلينا نبدأ بسؤال خفيف: شنو الحاجة البتفرحك اليوم؟',
    'شنو الشيء البتتمنى تلقى فيه شخص عنده نفس اهتمامك؟',
  ];

  static List<String> startersFor({
    String interest = '',
    String goal = '',
    String topic = '',
  }) {
    final result = <String>[];
    if (topic.trim().isNotEmpty) result.add('شنو رأيك في ' + topic.trim() + '؟');
    if (interest.trim().isNotEmpty) result.add('شنو أكتر جانب بتحبه في ' + interest.trim() + '؟');
    if (goal.trim().isNotEmpty) result.add('شنو الخطوة الجاية نحو ' + goal.trim() + '؟');
    result.addAll(starters);
    return result.toSet().take(8).toList();
  }

  static String safetyPrompt() =>
      'AUREN Random: لا تشارك كلمات المرور أو رموز التحقق أو بيانات الدفع أو عنوانك الدقيق.';

  static String translationHint(String sourceLanguage, String targetLanguage) =>
      'الترجمة المباشرة تحتاج خدمة ترجمة متصلة. اكتب: [' + sourceLanguage + ' → ' + targetLanguage + '] قبل الرسالة التي تريد ترجمتها.';
}
