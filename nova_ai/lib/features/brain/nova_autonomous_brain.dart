import 'dart:convert';

enum NovaStepStatus { pending, running, succeeded, blocked, failed }

class NovaBrainStep {
  const NovaBrainStep({
    required this.id,
    required this.title,
    required this.description,
    this.status = NovaStepStatus.pending,
    this.evidence = '',
  });

  final String id;
  final String title;
  final String description;
  final NovaStepStatus status;
  final String evidence;

  NovaBrainStep copyWith({NovaStepStatus? status, String? evidence}) =>
      NovaBrainStep(
        id: id,
        title: title,
        description: description,
        status: status ?? this.status,
        evidence: evidence ?? this.evidence,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.name,
        'evidence': evidence,
      };

  factory NovaBrainStep.fromJson(Map<String, dynamic> json) => NovaBrainStep(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        status: NovaStepStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => NovaStepStatus.pending,
        ),
        evidence: json['evidence'] as String? ?? '',
      );
}

class NovaBrainTask {
  const NovaBrainTask({
    required this.id,
    required this.goal,
    required this.createdAt,
    required this.steps,
  });

  final String id;
  final String goal;
  final String createdAt;
  final List<NovaBrainStep> steps;

  bool get isComplete =>
      steps.isNotEmpty &&
      steps.every((step) => step.status == NovaStepStatus.succeeded);

  int get completedSteps =>
      steps.where((step) => step.status == NovaStepStatus.succeeded).length;

  NovaBrainTask copyWith({List<NovaBrainStep>? steps}) => NovaBrainTask(
        id: id,
        goal: goal,
        createdAt: createdAt,
        steps: steps ?? this.steps,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'goal': goal,
        'createdAt': createdAt,
        'steps': steps.map((step) => step.toJson()).toList(),
      };

  factory NovaBrainTask.fromJson(Map<String, dynamic> json) => NovaBrainTask(
        id: json['id'] as String? ?? '',
        goal: json['goal'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
        steps: (json['steps'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(NovaBrainStep.fromJson)
            .toList(),
      );
}

/// Deterministic offline planner. It creates actionable plans but does not
/// pretend that external tools have run. Execution adapters can be registered
/// later and must return verifiable evidence before a step can succeed.
class NovaAutonomousPlanner {
  const NovaAutonomousPlanner();

  NovaBrainTask plan(String goal, {DateTime? now}) {
    final normalized = goal.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(goal, 'goal', 'The goal cannot be empty.');
    }

    final lower = normalized.toLowerCase();
    final steps = <({String title, String description})>[
      (
        title: 'تحديد النتيجة ومعيار النجاح',
        description:
            'حوّل الهدف إلى نتيجة قابلة للفحص وحدد القيود والموارد المطلوبة.',
      ),
      (
        title: 'فحص الحالة والمعلومات المتاحة',
        description:
            'اجمع الحالة الحالية والمصادر والأدوات المتاحة قبل اتخاذ أي إجراء.',
      ),
    ];

    if (_containsAny(lower, ['تطبيق', 'app', 'flutter', 'كود', 'برمج', 'build', 'بناء'])) {
      steps.addAll([
        (
          title: 'تحديد خطة التغيير',
          description:
              'قسّم العمل إلى تغييرات صغيرة مع ملفات مستهدفة ومعايير قبول.',
        ),
        (
          title: 'تنفيذ في نطاق معزول',
          description:
              'استخدم فرع تطوير وأدوات متاحة؛ لا تعدّل main مباشرة ولا تكشف الأسرار.',
        ),
        (
          title: 'تشغيل الاختبارات والبناء',
          description:
              'شغّل الفحوص المناسبة واحفظ روابط التشغيل والسجلات الفعلية.',
        ),
        (
          title: 'مراجعة النتيجة وإصلاح الفشل',
          description:
              'حلّل الفشل من السجلات، أصلح السبب، وأعد الاختبار ضمن حد للمحاولات.',
        ),
      ]);
    } else if (_containsAny(lower, ['فيديو', 'محتوى', 'ترند', 'youtube', 'تيك', 'منشور', 'تسويق'])) {
      steps.addAll([
        (
          title: 'جمع إشارات حديثة ومصادرها',
          description:
              'تحقق من تاريخ المصدر وملاءمة الموضوع للجمهور ولا تعتمد على إشارة واحدة.',
        ),
        (
          title: 'إعداد الفكرة والنسخ البديلة',
          description:
              'جهّز خطافات وعنواناً وسيناريو مناسباً للمنصة دون ادعاء ضمان الانتشار.',
        ),
        (
          title: 'إنتاج المحتوى وفحصه',
          description:
              'استخدم محركاً متاحاً ثم تحقق من الملف والصوت والترجمة والمقاس قبل اعتماده.',
        ),
        (
          title: 'قياس الأداء وتحديث الخطة',
          description:
              'سجّل مؤشرات الأداء الفعلية بعد النشر إن كان النشر والتحليلات موصولين.',
        ),
      ]);
    } else {
      steps.addAll([
        (
          title: 'مقارنة الخيارات واختيار الأقل كلفة',
          description:
              'قارن الأدوات والمخاطر والوقت والترخيص قبل اختيار مسار التنفيذ.',
        ),
        (
          title: 'تنفيذ الخطوات المسموح بها',
          description:
              'نفّذ فقط الإجراءات المدعومة بالأدوات والصلاحيات الحالية، واطلب الموافقة عند الحاجة.',
        ),
        (
          title: 'التحقق من النتيجة',
          description:
              'اختبر معيار النجاح، وسجّل الدليل أو سبب التعذر بوضوح.',
        ),
      ]);
    }

    steps.add((
      title: 'إعداد تقرير التنفيذ',
      description:
          'افصل بين ما تم التحقق منه وما لا يزال معطلاً أو يحتاج ربط أداة أو موافقة.',
    ));

    final timestamp = (now ?? DateTime.now()).toUtc();
    final id = 'nova-${timestamp.microsecondsSinceEpoch}';
    return NovaBrainTask(
      id: id,
      goal: normalized,
      createdAt: timestamp.toIso8601String(),
      steps: List.generate(
        steps.length,
        (index) => NovaBrainStep(
          id: '$id-step-${index + 1}',
          title: steps[index].title,
          description: steps[index].description,
        ),
      ),
    );
  }

  bool _containsAny(String text, List<String> terms) =>
      terms.any(text.contains);
}

String encodeNovaBrainTasks(List<NovaBrainTask> tasks) =>
    jsonEncode(tasks.map((task) => task.toJson()).toList());

List<NovaBrainTask> decodeNovaBrainTasks(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(NovaBrainTask.fromJson)
        .toList();
  } on FormatException {
    return const [];
  } on TypeError {
    return const [];
  }
}
