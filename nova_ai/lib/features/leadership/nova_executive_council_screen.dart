import 'package:flutter/material.dart';

/// Defines the planned NOVA operating model. Department heads and specialists
/// are role definitions; they are not live independent AI agents until connected.
class NovaExecutiveCouncilScreen extends StatelessWidget {
  const NovaExecutiveCouncilScreen({super.key});

  static const departments = <_Department>[
    _Department(
      name: 'الإدارة التنفيذية والاستراتيجية',
      head: 'NOVA Chief Executive AI',
      mission: 'المسؤول المباشر أمامك: يجمع تقارير الإدارات، يرتب الأولويات، يعرض الخلافات والتوصيات، ويتابع القرارات التي توافق عليها.',
      plan: 'تجميع تقارير الإدارات يومياً؛ ترتيب أهم 3 أولويات؛ عرض البدائل والتكلفة والوقت والمخاطر؛ ثم طلب قرارك وتسجيل النتيجة.',
      specialists: ['التخطيط الاستراتيجي', 'إدارة المشاريع والأولويات', 'قياس النتائج والمخاطر'],
      icon: Icons.account_balance,
    ),
    _Department(
      name: 'إدارة الأمن السيبراني والسلامة',
      head: 'AI Chief Security Officer',
      mission: 'يراجع أمن التطبيقات والخادم والحسابات والخصوصية، ويقود الاستجابة للحوادث واختبارات الدفاع المصرح بها.',
      plan: 'جرد المخاطر؛ مراجعة الصلاحيات والأسرار والقواعد؛ فرز الثغرات حسب الخطورة؛ متابعة إصلاحات موثقة وإعادة الاختبار.',
      specialists: ['أمن التطبيقات والكود', 'Firebase والخادم', 'الخصوصية وحماية البيانات', 'سلامة الملفات والجهاز', 'الاستجابة للحوادث'],
      icon: Icons.security,
    ),
    _Department(
      name: 'إدارة التطوير والهندسة',
      head: 'AI Chief Technology Officer',
      mission: 'يخطط للهندسة ويقود مراجعة الكود وإصلاح العيوب وتكامل الأنظمة.',
      plan: 'مراجعة بنية المشروع؛ تقسيم العمل إلى تغييرات صغيرة؛ تنفيذ إصلاحات قابلة للمراجعة؛ متابعة البناء والاختبارات قبل اقتراح الدمج.',
      specialists: ['Flutter وAndroid', 'الخادم وواجهات API', 'قواعد البيانات والمزامنة', 'البناء والإصدارات'],
      icon: Icons.code,
    ),
    _Department(
      name: 'إدارة الجودة والاختبارات',
      head: 'AI Quality Director',
      mission: 'يتحقق من المتطلبات والاختبارات والتوافق، ولا يعلن نجاح ميزة دون أدلة اختبار.',
      plan: 'إنشاء مصفوفة متطلبات واختبارات؛ إعادة إنتاج العيوب؛ التحقق من نجاح CI؛ منع إعلان أي إنجاز بلا دليل.',
      specialists: ['اختبارات الوحدة والتكامل', 'اختبارات الواجهات', 'مراجعة CI وسجلات الفشل', 'اختبارات الأداء والإتاحة'],
      icon: Icons.fact_check_outlined,
    ),
    _Department(
      name: 'إدارة البحث والذكاء الاصطناعي',
      head: 'AI Research Director',
      mission: 'يقارن النماذج والأدوات، ويقيس الجودة والتكلفة والخصوصية قبل اقتراح اعتماد أي خدمة.',
      plan: 'البحث في المصادر الحديثة؛ مقارنة الأدوات والنماذج والتكلفة؛ التحقق من الادعاءات؛ تقديم توصية مع المصادر ودرجة الثقة.',
      specialists: ['تقييم النماذج', 'الوكلاء وتنسيق المهام', 'العمل دون إنترنت', 'تقييم المصادر والدقة'],
      icon: Icons.psychology_outlined,
    ),
    _Department(
      name: 'إدارة المنتج وتجربة المستخدم',
      head: 'AI Product Director',
      mission: 'يربط احتياجاتك بخطة المنتج، ويضمن الوضوح وسهولة الاستخدام وإمكانية الوصول.',
      plan: 'جمع احتياجات المستخدم؛ ترتيبها حسب القيمة والجهد؛ مراجعة سهولة الاستخدام والإتاحة؛ اقتراح تجربة قابلة للقياس.',
      specialists: ['أبحاث المستخدمين', 'تصميم UX/UI', 'إدارة المتطلبات', 'اللغة والتوطين'],
      icon: Icons.design_services_outlined,
    ),
    _Department(
      name: 'إدارة التسويق والنمو',
      head: 'AI Growth Director',
      mission: 'يبحث عن الجمهور والفرص ويقترح تجارب نمو قابلة للقياس دون نشر أو إنفاق غير مصرح به.',
      plan: 'تحديد الجمهور والقنوات؛ تحليل المنافسين والاتجاهات؛ إعداد تجارب محتوى ونمو؛ قياس النتائج دون نشر آلي غير مصرح به.',
      specialists: ['تحليل السوق والمنافسين', 'استراتيجية المحتوى', 'النمو والتحليلات', 'الشراكات والمجتمعات'],
      icon: Icons.trending_up,
    ),
    _Department(
      name: 'الإدارة المالية والإيرادات',
      head: 'AI Finance Director',
      mission: 'يبني التوقعات والميزانيات وسيناريوهات الدخل، ويفصل بين التقديرات والأموال المحققة فعلياً.',
      plan: 'حصر مصادر الدخل والتكاليف؛ إعداد توقعات متحفظة ومتوسطة ومتفائلة؛ تمييز الدخل الفعلي عن المتوقع؛ تجنب ضمان الأرباح.',
      specialists: ['التخطيط المالي', 'تحليل مصادر الدخل', 'التكاليف والميزانيات', 'مخاطر الاستثمار'],
      icon: Icons.account_balance_wallet_outlined,
    ),
    _Department(
      name: 'الإدارة القانونية والامتثال',
      head: 'AI Legal & Compliance Director',
      mission: 'يرصد المسائل القانونية والخصوصية وحقوق النشر وشروط المنصات؛ ويحدد متى يلزم رأي مختص بشري.',
      plan: 'مراجعة الخصوصية والتراخيص وشروط المنصات؛ تسجيل المسائل غير المحسومة؛ اقتراح ضوابط؛ إحالة المسائل المتخصصة لمختص بشري.',
      specialists: ['الخصوصية والبيانات', 'شروط المنصات', 'حقوق النشر والتراخيص', 'مراجعة المخاطر التنظيمية'],
      icon: Icons.gavel_outlined,
    ),
    _Department(
      name: 'إدارة العمليات والمساعد التنفيذي',
      head: 'AI Operations Director',
      mission: 'ينظم المهام والتقارير والمواعيد والبريد والمسودات، ولا يرسل رسائل أو ينفذ التزامات خارجية دون صلاحية وموافقة.',
      plan: 'تنظيم قائمة المهام والمواعيد؛ تجهيز مسودات البريد والردود؛ متابعة الأعمال المفتوحة؛ عدم الإرسال أو الالتزام نيابة عن المستخدم دون موافقة.',
      specialists: ['إدارة المهام والمتابعة', 'البريد وصياغة الردود', 'التوثيق والتقارير', 'التنسيق بين الإدارات'],
      icon: Icons.assignment_turned_in_outlined,
    ),
    _Department(
      name: 'إدارة AUREN والمنتج المستقبلي',
      head: 'AI AUREN Program Director',
      mission: 'يدير خارطة طريق AUREN، ينظم الأفكار والملفات، ويقدم تحديثات التقدم والاحتياجات ومخاطر التنفيذ.',
      plan: 'ترتيب أفكار AUREN وملفاتها؛ مراجعة خارطة الطريق وPR وحالة CI؛ تحديد أولويات السوق؛ رفع تقرير بالتقدم والعوائق والخطوة التالية.',
      specialists: ['خارطة الطريق', 'مراجعة المستودع وPR', 'تحليل احتياجات السوق', 'التكامل والجاهزية للإطلاق'],
      icon: Icons.hub_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مجلس الإدارة التنفيذية لـ NOVA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person_pin_circle_outlined, size: 36),
                  const SizedBox(height: 8),
                  const Text('أنت صاحب القرار النهائي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('المسؤول المباشر معك هو NOVA Chief Executive AI. يستقبل تقارير رؤساء الإدارات، يشرح الخيارات والمخاطر والتكلفة والوقت، ثم يرفع لك توصية واضحة. لا يملك حق تجاوز موافقتك في الإجراءات الحساسة.'),
                  const SizedBox(height: 12),
                  const _GovernanceRule(text: 'كل إدارة لها رئيس AI متخصص ومسؤوليات محددة.'),
                  const _GovernanceRule(text: 'تحت كل رئيس فريق خبراء حسب التخصص، مع مراجعة متقاطعة عند الحاجة.'),
                  const _GovernanceRule(text: 'كل تقرير يميز بين: تم اختباره، قيد التنفيذ، مخطط، ومتعذر.'),
                  const _GovernanceRule(text: 'النشر، الإنفاق، إرسال الرسائل، تغيير الصلاحيات أو الوصول للبيانات الحساسة يحتاج موافقة صريحة.'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const _DepartmentIntroductionsDialog(),
                      ),
                      icon: const Icon(Icons.record_voice_over_outlined),
                      label: const Text('ابدأ جلسة تعارف رؤساء الإدارات'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('الإدارات ورؤساؤها', textDirection: TextDirection.rtl, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final department in departments)
            Card(
              child: ExpansionTile(
                leading: Icon(department.icon),
                title: Text(department.name, textDirection: TextDirection.rtl),
                subtitle: Text(department.head, textDirection: TextDirection.ltr),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تعريف رئيس الإدارة: أنا ${department.head}، وأتولى ${department.name}، وأرفع تقاريري إلى NOVA Chief Executive AI ثم إليك صاحب القرار النهائي.', textDirection: TextDirection.rtl),
                  const SizedBox(height: 8),
                  Text('مهمتي: ${department.mission}', textDirection: TextDirection.rtl),
                  const SizedBox(height: 10),
                  const Text('خطتي العملية', textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(department.plan, textDirection: TextDirection.rtl),
                  const SizedBox(height: 10),
                  const Text('التخصصات التابعة', textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  for (final specialist in department.specialists)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_outline, size: 19),
                      title: Text(specialist, textDirection: TextDirection.rtl),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'حالة التنفيذ: هذا المجلس يحدد الهيكل والأدوار داخل الواجهة. لا يعني ذلك أن جميع رؤساء الإدارات أو الخبراء يعملون الآن كوكلاء AI مستقلين. يلزم ربطهم بمحركات فعلية، وصلاحيات محدودة، وسجل تدقيق، واختبارات قبل وصفهم بأنهم نشطون.',
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

class _DepartmentIntroductionsDialog extends StatefulWidget {
  const _DepartmentIntroductionsDialog();

  @override
  State<_DepartmentIntroductionsDialog> createState() => _DepartmentIntroductionsDialogState();
}

class _DepartmentIntroductionsDialogState extends State<_DepartmentIntroductionsDialog> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final department = NovaExecutiveCouncilScreen.departments[index];
    final isLast = index == NovaExecutiveCouncilScreen.departments.length - 1;
    return AlertDialog(
      title: Text('جلسة التعارف: ${index + 1} من ${NovaExecutiveCouncilScreen.departments.length}', textDirection: TextDirection.rtl),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(department.head, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('من أنا؟', textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold)),
            Text('أنا ${department.head}، رئيس ${department.name}. أرفع تقاريري إلى NOVA Chief Executive AI، وهو مسؤول أمامك مباشرة.', textDirection: TextDirection.rtl),
            const SizedBox(height: 10),
            const Text('مهمتي', textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(department.mission, textDirection: TextDirection.rtl),
            const SizedBox(height: 10),
            const Text('خطتي', textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(department.plan, textDirection: TextDirection.rtl),
            const SizedBox(height: 10),
            const Text('فريق التخصصات', textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold)),
            ...department.specialists.map((name) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• $name', textDirection: TextDirection.rtl),
            )),
            const SizedBox(height: 12),
            const Text(
              'تنبيه: هذا تعريف وخطة معلنة داخل التطبيق؛ لا يعني أن هذا الرئيس أو فريقه وكيل مستقل نشط قبل ربط نموذج AI وتنفيذ المهام واختبارهما.',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: index == 0 ? null : () => setState(() => index--),
          child: const Text('السابق'),
        ),
        FilledButton(
          onPressed: () {
            if (isLast) {
              Navigator.of(context).pop();
            } else {
              setState(() => index++);
            }
          },
          child: Text(isLast ? 'إنهاء الجلسة' : 'التالي'),
        ),
      ],
    );
  }
}

class _Department {
  const _Department({
    required this.name,
    required this.head,
    required this.mission,
    required this.plan,
    required this.specialists,
    required this.icon,
  });

  final String name;
  final String head;
  final String mission;
  final String plan;
  final List<String> specialists;
  final IconData icon;
}

class _GovernanceRule extends StatelessWidget {
  const _GovernanceRule({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.verified_user_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(text, textDirection: TextDirection.rtl)),
          ],
        ),
      );
}
