/// NOVA's deterministic engineering team registry and safe task router.
///
/// This is a planning/routing layer only. It does not spawn agents, edit files,
/// execute shell commands, publish releases, or claim that CI passed. A future
/// worker adapter must enforce the approval policy before any external action.
enum NovaEngineeringRole {
  architect,
  flutterUi,
  backendApi,
  security,
  testEngineer,
  buildRelease,
  codeReviewer,
}

enum NovaEngineeringRisk { low, medium, high }

class NovaEngineeringDepartment {
  const NovaEngineeringDepartment({
    required this.role,
    required this.name,
    required this.mandate,
    required this.keywords,
  });

  final NovaEngineeringRole role;
  final String name;
  final String mandate;
  final List<String> keywords;
}

class NovaEngineeringAssignment {
  const NovaEngineeringAssignment({
    required this.goal,
    required this.roles,
    required this.risk,
    required this.requiresHumanApproval,
    required this.reason,
  });

  final String goal;
  final List<NovaEngineeringRole> roles;
  final NovaEngineeringRisk risk;
  final bool requiresHumanApproval;
  final String reason;
}

class NovaEngineeringOrchestrator {
  const NovaEngineeringOrchestrator();

  static const departments = <NovaEngineeringDepartment>[
    NovaEngineeringDepartment(
      role: NovaEngineeringRole.architect,
      name: 'مهندس المعمارية',
      mandate: 'يفحص البنية والتبعيات ويقسم العمل إلى تغييرات صغيرة.',
      keywords: ['architecture', 'architect', 'design', 'structure', 'معمار', 'بنية', 'تصميم'],
    ),
    NovaEngineeringDepartment(
      role: NovaEngineeringRole.flutterUi,
      name: 'مهندس Flutter والواجهة',
      mandate: 'يتولى واجهات Flutter وإمكانية الوصول وتجربة الاستخدام.',
      keywords: ['flutter', 'widget', 'screen', 'ui', 'ux', 'واجهة', 'شاشة', 'تصميم'],
    ),
    NovaEngineeringDepartment(
      role: NovaEngineeringRole.backendApi,
      name: 'مهندس الخلفية وواجهات API',
      mandate: 'يتولى الخدمات وواجهات API وتكاملات الخادم.',
      keywords: ['backend', 'api', 'function', 'firebase', 'server', 'خلفية', 'خادم', 'تكامل'],
    ),
    NovaEngineeringDepartment(
      role: NovaEngineeringRole.security,
      name: 'مهندس الأمان والخصوصية',
      mandate: 'يراجع الأسرار والصلاحيات والتحقق من المدخلات وحدود الثقة.',
      keywords: ['security', 'privacy', 'secret', 'auth', 'permission', 'أمان', 'خصوصية', 'صلاحيات'],
    ),
    NovaEngineeringDepartment(
      role: NovaEngineeringRole.testEngineer,
      name: 'مهندس الاختبارات والجودة',
      mandate: 'يحدد معايير القبول ويشغل الاختبارات ويتحقق من الأدلة.',
      keywords: ['test', 'testing', 'bug', 'failure', 'analyze', 'اختبار', 'فشل', 'خطأ', 'جودة'],
    ),
    NovaEngineeringDepartment(
      role: NovaEngineeringRole.buildRelease,
      name: 'مهندس البناء والإصدار',
      mandate: 'يراجع CI والبناء وحزم Android وسجلات الإصدار.',
      keywords: ['build', 'apk', 'android', 'ci', 'release', 'workflow', 'بناء', 'اندرويد', 'إصدار'],
    ),
    NovaEngineeringDepartment(
      role: NovaEngineeringRole.codeReviewer,
      name: 'مراجع الكود',
      mandate: 'يفحص الفرق والتكرار وقابلية الصيانة قبل اقتراح الدمج.',
      keywords: ['review', 'diff', 'merge', 'pull request', 'pr', 'مراجعة', 'دمج', 'تغيير'],
    ),
  ];

  NovaEngineeringAssignment plan(String rawGoal) {
    final goal = rawGoal.trim();
    if (goal.isEmpty) {
      throw ArgumentError.value(rawGoal, 'rawGoal', 'Goal must not be empty.');
    }

    final normalized = goal.toLowerCase();
    final matched = <NovaEngineeringRole>[];
    for (final department in departments) {
      if (department.keywords.any(normalized.contains)) {
        matched.add(department.role);
      }
    }

    // A generic engineering request always gets architecture, tests and review.
    if (matched.isEmpty) {
      matched.addAll([
        NovaEngineeringRole.architect,
        NovaEngineeringRole.testEngineer,
        NovaEngineeringRole.codeReviewer,
      ]);
    } else {
      if (!matched.contains(NovaEngineeringRole.architect)) {
        matched.insert(0, NovaEngineeringRole.architect);
      }
      if (!matched.contains(NovaEngineeringRole.testEngineer)) {
        matched.add(NovaEngineeringRole.testEngineer);
      }
      if (!matched.contains(NovaEngineeringRole.codeReviewer)) {
        matched.add(NovaEngineeringRole.codeReviewer);
      }
    }

    final highRiskTerms = [
      'payment', 'transfer', 'publish', 'deploy', 'delete', 'secret',
      'credential', 'production', 'payment', 'نشر', 'حذف', 'دفع',
      'تحويل', 'إنتاج', 'مفتاح', 'سر',
    ];
    final mediumRiskTerms = [
      'firebase', 'auth', 'permission', 'database', 'firestore',
      'قاعدة بيانات', 'صلاحيات', 'حساب',
    ];
    final highRisk = highRiskTerms.any(normalized.contains);
    final mediumRisk = mediumRiskTerms.any(normalized.contains);

    return NovaEngineeringAssignment(
      goal: goal,
      roles: List.unmodifiable(matched.toSet()),
      risk: highRisk
          ? NovaEngineeringRisk.high
          : mediumRisk
              ? NovaEngineeringRisk.medium
              : NovaEngineeringRisk.low,
      // All repository writes, deploys, publishing, payments and destructive
      // actions stay behind explicit owner approval, regardless of risk score.
      requiresHumanApproval: true,
      reason: highRisk
          ? 'طلب عالي الحساسية: يلزم فحص الخطة والفرق والاختبارات وموافقة المالك قبل التنفيذ.'
          : 'خطة توزيع فقط؛ يلزم فحص المستودع والأدلة قبل التنفيذ أو إعلان النجاح.',
    );
  }
}
