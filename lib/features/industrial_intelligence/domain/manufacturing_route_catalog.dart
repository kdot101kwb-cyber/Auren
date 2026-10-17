/// Illustrative manufacturing routes for discovery and planning.
/// These templates are starting points only: actual processing requirements,
/// yields, safety controls and certifications depend on material grade,
/// product specification, jurisdiction and qualified engineering review.
class ManufacturingStage {
  final String name;
  final String purpose;
  final List<String> typicalInputs;
  final List<String> typicalOutputs;
  final List<String> considerations;

  const ManufacturingStage({
    required this.name,
    required this.purpose,
    required this.typicalInputs,
    required this.typicalOutputs,
    required this.considerations,
  });
}

class ManufacturingRoute {
  final String id;
  final String rawMaterial;
  final String finalProduct;
  final String overview;
  final List<ManufacturingStage> stages;
  final List<String> prerequisites;

  const ManufacturingRoute({
    required this.id,
    required this.rawMaterial,
    required this.finalProduct,
    required this.overview,
    required this.stages,
    required this.prerequisites,
  });
}

class ManufacturingRouteCatalog {
  static const routes = <ManufacturingRoute>[
    ManufacturingRoute(
      id: 'cotton-to-garment',
      rawMaterial: 'القطن',
      finalProduct: 'الملابس القطنية',
      overview: 'مسار توضيحي من الألياف الخام إلى منتج نسيجي جاهز.',
      prerequisites: [
        'تحديد درجة الألياف ومواصفات المنتج النهائي',
        'تأكيد توفر المياه والطاقة والمعدات والعمالة المؤهلة',
        'التحقق من متطلبات السلامة والجودة والتعبئة في السوق المستهدف',
      ],
      stages: [
        ManufacturingStage(
          name: 'الحلج والتنظيف',
          purpose: 'فصل الألياف عن البذور وإزالة الشوائب وفرز الخام.',
          typicalInputs: ['قطن خام'],
          typicalOutputs: ['ألياف قطنية', 'بذور قطن', 'شوائب منفصلة'],
          considerations: ['الرطوبة', 'نظافة الألياف', 'الفاقد الفعلي'],
        ),
        ManufacturingStage(
          name: 'الغزل',
          purpose: 'تحويل الألياف إلى خيوط بالمواصفات المطلوبة.',
          typicalInputs: ['ألياف مصنفة'],
          typicalOutputs: ['خيوط قطنية'],
          considerations: ['نعومة الخيط', 'الالتواء', 'قوة الشد', 'استهلاك الطاقة'],
        ),
        ManufacturingStage(
          name: 'النسيج أو الحياكة',
          purpose: 'إنتاج القماش المناسب للتصميم.',
          typicalInputs: ['خيوط قطنية'],
          typicalOutputs: ['قماش خام'],
          considerations: ['وزن القماش', 'عرضه', 'عيوب النسيج'],
        ),
        ManufacturingStage(
          name: 'التجهيز والصباغة',
          purpose: 'معالجة القماش وفق مواصفات اللون والاستخدام.',
          typicalInputs: ['قماش خام', 'مواد تجهيز معتمدة'],
          typicalOutputs: ['قماش مجهز'],
          considerations: ['معالجة مياه الصرف', 'ثبات اللون', 'السلامة الكيميائية'],
        ),
        ManufacturingStage(
          name: 'القص والخياطة والتعبئة',
          purpose: 'تحويل القماش إلى ملابس أو منتجات نسيجية نهائية.',
          typicalInputs: ['قماش مجهز', 'مستلزمات خياطة', 'مواد تعبئة'],
          typicalOutputs: ['ملابس مفحوصة ومعبأة'],
          considerations: ['مقاسات المنتج', 'الهدر من القص', 'فحص الجودة والملصقات'],
        ),
      ],
    ),
    ManufacturingRoute(
      id: 'sesame-to-tahini',
      rawMaterial: 'السمسم',
      finalProduct: 'الطحينة',
      overview: 'مسار غذائي نموذجي يتطلب ضوابط سلامة غذائية مناسبة.',
      prerequisites: [
        'اختبارات قبول الخام والشوائب والرطوبة والملوثات',
        'خطة سلامة غذاء مناسبة للسوق المستهدف',
        'تأكيد مواصفات التعبئة وفترة الصلاحية من خلال الاختبارات',
      ],
      stages: [
        ManufacturingStage(
          name: 'الاستلام والفرز والتنظيف',
          purpose: 'فحص السمسم وتنظيفه وإزالة المواد الغريبة.',
          typicalInputs: ['سمسم خام'],
          typicalOutputs: ['سمسم منظف ومصنف'],
          considerations: ['المخاطر الميكروبية', 'الشوائب', 'التتبع'],
        ),
        ManufacturingStage(
          name: 'المعالجة الحرارية حسب الوصفة',
          purpose: 'إعداد السمسم وفق وصفة وعملية معتمدة.',
          typicalInputs: ['سمسم منظف'],
          typicalOutputs: ['سمسم معالج'],
          considerations: ['التحقق من العملية', 'التحكم في الحرارة', 'سلامة الغذاء'],
        ),
        ManufacturingStage(
          name: 'الطحن والتجانس',
          purpose: 'تحويل السمسم إلى معجون بالمواصفات المستهدفة.',
          typicalInputs: ['سمسم معالج'],
          typicalOutputs: ['طحينة'],
          considerations: ['قوام المنتج', 'درجة الطحن', 'نظافة المعدات'],
        ),
        ManufacturingStage(
          name: 'الفحص والتعبئة',
          purpose: 'فحص المنتج وتعبئته وترميزه للتتبع.',
          typicalInputs: ['طحينة', 'عبوات وملصقات مناسبة'],
          typicalOutputs: ['عبوات طحينة جاهزة للبيع'],
          considerations: ['سلامة العبوة', 'بيانات الملصق', 'التحقق من الصلاحية'],
        ),
      ],
    ),
    ManufacturingRoute(
      id: 'peanut-to-peanut-butter',
      rawMaterial: 'الفول السوداني',
      finalProduct: 'زبدة الفول السوداني',
      overview: 'مسار غذائي توضيحي مع ضرورة إدارة مخاطر الحساسية والملوثات.',
      prerequisites: [
        'فحص الخام ومخاطر السموم الفطرية وفق المتطلبات المعمول بها',
        'إدارة حساسية الفول السوداني ومنع التلوث التبادلي',
        'التحقق من مواصفات المنتج وفترة الصلاحية',
      ],
      stages: [
        ManufacturingStage(
          name: 'الفرز والتنظيف',
          purpose: 'إزالة الحبوب التالفة والمواد الغريبة.',
          typicalInputs: ['فول سوداني خام'],
          typicalOutputs: ['فول سوداني مقبول للتصنيع'],
          considerations: ['الملوثات', 'الفرز', 'تتبع الدفعات'],
        ),
        ManufacturingStage(
          name: 'التحميص والتبريد',
          purpose: 'تهيئة الحبوب وفق عملية حرارية موثقة.',
          typicalInputs: ['فول سوداني مصنف'],
          typicalOutputs: ['فول سوداني محمص'],
          considerations: ['التحقق من العملية', 'التبريد الصحي', 'مخاطر الحريق'],
        ),
        ManufacturingStage(
          name: 'إزالة القشرة والطحن',
          purpose: 'إنتاج معجون بالقوام المطلوب.',
          typicalInputs: ['فول سوداني محمص'],
          typicalOutputs: ['معجون فول سوداني'],
          considerations: ['القوام', 'الزيوت المضافة إن وجدت', 'تنظيف المعدات'],
        ),
        ManufacturingStage(
          name: 'الفحص والتعبئة',
          purpose: 'تعبئة المنتج ووضع بيانات الحساسية والتتبع.',
          typicalInputs: ['معجون', 'عبوات مناسبة'],
          typicalOutputs: ['زبدة فول سوداني معبأة'],
          considerations: ['ملصق الحساسية', 'سلامة العبوات', 'اختبارات الصلاحية'],
        ),
      ],
    ),
    ManufacturingRoute(
      id: 'hides-to-leather-goods',
      rawMaterial: 'الجلود الخام',
      finalProduct: 'منتجات جلدية',
      overview: 'مسار يحتاج خبرة دباغة وإدارة بيئية للمواد الكيميائية ومياه الصرف.',
      prerequisites: [
        'فرز الجلود حسب الحالة والحجم والعيوب',
        'تقييم المعالجة الكيميائية والسلامة المهنية',
        'خطة معالجة للنفايات ومياه الصرف والامتثال البيئي',
      ],
      stages: [
        ManufacturingStage(
          name: 'الاستلام والحفظ والفرز',
          purpose: 'تقييم حالة الجلود وفرزها لتقليل التلف.',
          typicalInputs: ['جلود خام'],
          typicalOutputs: ['جلود مصنفة'],
          considerations: ['الحفظ', 'التلف', 'التتبع'],
        ),
        ManufacturingStage(
          name: 'المعالجة والدباغة',
          purpose: 'تحويل الجلد الخام إلى جلد مستقر وفق مواصفات محددة.',
          typicalInputs: ['جلود مصنفة', 'مواد معالجة معتمدة'],
          typicalOutputs: ['جلد مدبوغ'],
          considerations: ['السلامة الكيميائية', 'مياه الصرف', 'متطلبات البيئة'],
        ),
        ManufacturingStage(
          name: 'التجفيف والتشطيب',
          purpose: 'ضبط الخصائص والمظهر النهائي للجلد.',
          typicalInputs: ['جلد مدبوغ'],
          typicalOutputs: ['جلد مشطب'],
          considerations: ['السماكة', 'اللون', 'المرونة', 'الفحص'],
        ),
        ManufacturingStage(
          name: 'التصميم والقص والتجميع',
          purpose: 'تصنيع أحذية أو حقائب أو أحزمة أو منتجات أخرى.',
          typicalInputs: ['جلد مشطب', 'مكونات وملحقات'],
          typicalOutputs: ['منتجات جلدية مفحوصة'],
          considerations: ['هدر القص', 'متانة الوصلات', 'المقاسات والتعبئة'],
        ),
      ],
    ),
    ManufacturingRoute(
      id: 'iron-to-fabricated-products',
      rawMaterial: 'خام الحديد',
      finalProduct: 'منتجات حديدية مصنعة',
      overview: 'مثال عام لسلسلة معدنية؛ اختيار المسار يعتمد على نوع الخام والبنية الصناعية المتاحة.',
      prerequisites: [
        'تحليل تركيب الخام والجدوى الطاقية واللوجستية',
        'تقييم بيئي وسلامة صناعية من مختصين',
        'تحديد مواصفات المنتج ومعايير اختباره',
      ],
      stages: [
        ManufacturingStage(
          name: 'تحضير الخام',
          purpose: 'تجهيز الخام حسب خصائصه ومتطلبات العملية.',
          typicalInputs: ['خام حديد'],
          typicalOutputs: ['خام مجهز'],
          considerations: ['التركيب', 'حجم الحبيبات', 'المخلفات'],
        ),
        ManufacturingStage(
          name: 'استخلاص الحديد أو إنتاج المعدن الوسيط',
          purpose: 'إنتاج مادة معدنية وسيطة باستخدام تقنية صناعية ملائمة.',
          typicalInputs: ['خام مجهز', 'مدخلات العملية الصناعية'],
          typicalOutputs: ['حديد أو معدن وسيط'],
          considerations: ['الطاقة', 'الانبعاثات', 'السلامة', 'جودة المعدن'],
        ),
        ManufacturingStage(
          name: 'الصهر أو التشكيل',
          purpose: 'إنتاج أشكال نصف مصنعة بحسب مواصفات المنتج.',
          typicalInputs: ['معدن وسيط'],
          typicalOutputs: ['قضبان أو صفائح أو مقاطع بحسب الخط'],
          considerations: ['الخصائص الميكانيكية', 'الأبعاد', 'اختبارات الجودة'],
        ),
        ManufacturingStage(
          name: 'التصنيع والفحص',
          purpose: 'تحويل الأشكال المعدنية إلى مكونات أو منتجات قابلة للبيع.',
          typicalInputs: ['أشكال معدنية نصف مصنعة'],
          typicalOutputs: ['منتجات معدنية مفحوصة'],
          considerations: ['التفاوتات', 'اللحام والتشطيب', 'المعايير المطلوبة'],
        ),
      ],
    ),
  ];

  static ManufacturingRoute? findById(String id) {
    final query = id.trim().toLowerCase();
    if (query.isEmpty) return null;
    for (final route in routes) {
      if (route.id.toLowerCase() == query) return route;
    }
    return null;
  }

  static ManufacturingRoute? findByRawMaterial(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return null;
    for (final route in routes) {
      if (route.id.toLowerCase() == query ||
          route.rawMaterial.toLowerCase() == query ||
          route.finalProduct.toLowerCase() == query) {
        return route;
      }
    }
    return null;
  }
}
