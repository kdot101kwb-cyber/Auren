/// Route-aware stage labels and descriptions for the illustrative planner.
class RawToProductStageStrings {
  static const _data = <String, Map<String, List<String>>>{
    'cotton-to-garment': {
      'en': ['Ginning and cleaning|Separate lint from seeds and remove foreign matter.', 'Spinning|Turn classified cotton fibres into yarn.', 'Weaving or knitting|Make fabric to the intended construction.', 'Fabric finishing and dyeing|Finish fabric to the required use and colour.', 'Cutting, sewing and packing|Turn finished fabric into inspected garments.'],
      'ar': ['الحلج والتنظيف|فصل الألياف عن البذور وإزالة الشوائب.', 'الغزل|تحويل الألياف المصنفة إلى خيوط.', 'النسيج أو الحياكة|إنتاج القماش بالتركيب المطلوب.', 'تجهيز القماش والصباغة|تجهيز القماش وفق اللون والاستخدام المستهدفين.', 'القص والخياطة والتعبئة|تحويل القماش إلى ملابس مفحوصة.'],
    },
    'sesame-to-tahini': {
      'en': ['Receive, sort and clean sesame|Inspect the seed and remove foreign matter.', 'Validated heat treatment|Apply a food-safe process validated for the product.', 'Grinding and homogenizing|Grind processed sesame to the target paste texture.', 'Quality checks and filling|Check the product and fill suitable traceable packs.'],
      'ar': ['استلام السمسم وفرزه وتنظيفه|فحص السمسم وإزالة المواد الغريبة.', 'المعالجة الحرارية المعتمدة|تطبيق عملية مناسبة لسلامة الغذاء والتحقق منها.', 'الطحن والتجانس|طحن السمسم المعالج إلى قوام الطحينة المستهدف.', 'فحص الجودة والتعبئة|فحص المنتج وتعبئته في عبوات مناسبة قابلة للتتبع.'],
    },
    'peanut-to-peanut-butter': {
      'en': ['Sort and clean peanuts|Remove damaged kernels and foreign matter.', 'Controlled roasting and cooling|Use a validated process and hygienic cooling.', 'Skin removal and grinding|Make a paste with the required texture.', 'Allergen labelling and packing|Check the product and clearly declare peanuts.'],
      'ar': ['فرز الفول السوداني وتنظيفه|إزالة الحبوب التالفة والمواد الغريبة.', 'التحميص والتبريد المنضبط|استخدام عملية متحقق منها وتبريد صحي.', 'إزالة القشرة والطحن|إنتاج معجون بالقوام المطلوب.', 'بيان مسببات الحساسية والتعبئة|فحص المنتج والتصريح بوضوح عن الفول السوداني.'],
    },
    'hides-to-leather-goods': {
      'en': ['Receive, preserve and grade hides|Assess condition and sort hides to reduce damage.', 'Treatment and tanning|Convert hides to stable leather using controlled processes.', 'Drying and finishing|Set the leather properties and surface finish.', 'Design, cutting and assembly|Make and inspect leather goods to specification.'],
      'ar': ['استلام الجلود وحفظها وفرزها|تقييم حالة الجلود وفرزها لتقليل التلف.', 'المعالجة والدباغة|تحويل الجلود إلى جلد مستقر بعمليات مضبوطة.', 'التجفيف والتشطيب|ضبط خصائص الجلد ومظهره النهائي.', 'التصميم والقص والتجميع|تصنيع المنتجات الجلدية وفحصها وفق المواصفات.'],
    },
    'iron-to-fabricated-products': {
      'en': ['Ore preparation and characterization|Assess composition and prepare feed for the selected process.', 'Iron extraction or intermediate production|Choose a suitable industrial route after engineering review.', 'Casting, rolling or shaping|Produce semi-finished stock to defined specifications.', 'Fabrication and inspection|Manufacture and inspect final metal products.'],
      'ar': ['تحضير الخام وتحليل خصائصه|تحليل التركيب وتجهيز الخام للعملية المختارة.', 'استخلاص الحديد أو إنتاج معدن وسيط|اختيار المسار الصناعي بعد مراجعة هندسية متخصصة.', 'الصب أو الدرفلة أو التشكيل|إنتاج مواد نصف مصنعة بمواصفات محددة.', 'التصنيع والفحص|تصنيع المنتجات المعدنية النهائية وفحصها.'],
    },
  };

  static String name(String routeId, int index, String languageCode, String fallback) {
    final entries = _data[routeId]?[languageCode];
    if (entries == null || index < 0 || index >= entries.length) return fallback;
    return entries[index].split('|').first;
  }

  static String purpose(String routeId, int index, String languageCode, String fallback) {
    final entries = _data[routeId]?[languageCode];
    if (entries == null || index < 0 || index >= entries.length) return fallback;
    return entries[index].split('|').skip(1).join('|');
  }
}
