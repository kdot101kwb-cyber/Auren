/// Curated free/open-source game-development toolkit for NOVA.
/// Catalogue entries are not claims that dependencies are installed or connected.
library;

enum NovaGameToolKind {
  engine, art, aiBridge, terrain, physics, npcAi, dialogue, camera, optimization,
  webEngine, pixelArt, materials, assets, audio, examples,
}

class NovaGameTool {
  const NovaGameTool({
    required this.id,
    required this.name,
    required this.kind,
    required this.repository,
    required this.purpose,
    required this.licenseNote,
    required this.integrationStatus,
    this.compatibilityNote = '',
  });

  final String id;
  final String name;
  final NovaGameToolKind kind;
  final String repository;
  final String purpose;
  final String licenseNote;
  final String integrationStatus;
  final String compatibilityNote;
}

class NovaGameToolCatalog {
  NovaGameToolCatalog._();

  static const statusCatalogOnly = 'catalog_only';

  static const tools = <NovaGameTool>[
    NovaGameTool(
      id: 'godot-engine',
      name: 'Godot Engine',
      kind: NovaGameToolKind.engine,
      repository: 'https://github.com/godotengine/godot',
      purpose: 'المحرك الأساسي لبناء ألعاب 2D و3D وتصديرها للمنصات المدعومة.',
      licenseNote: 'MIT; مجاني ومفتوح المصدر.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'يتطلب تثبيت المحرك وبيئة بناء مناسبة؛ وجود الرابط لا يعني أن البناء من هاتف Android متاح.',
    ),
    NovaGameTool(
      id: 'blender',
      name: 'Blender',
      kind: NovaGameToolKind.art,
      repository: 'https://github.com/blender/blender',
      purpose: 'إنشاء المجسمات والشخصيات والتحريك والخامات واللقطات.',
      licenseNote: 'GPL; مجاني ومفتوح المصدر.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'يعمل عادة على حاسوب أو مضيف بناء، وليس كأداة تحرير كاملة داخل تطبيق Flutter.',
    ),
    NovaGameTool(
      id: 'godot-ai-workbench',
      name: 'Godot AI Workbench',
      kind: NovaGameToolKind.aiBridge,
      repository: 'https://github.com/ZemDen/godot-ai-workbench',
      purpose: 'جسر MCP لوكلاء الذكاء الاصطناعي لفحص المشاهد والموارد وتشغيل الاختبارات وقراءة الأخطاء.',
      licenseNote: 'مشروع مفتوح المصدر؛ راجع الترخيص والإصدار الحالي قبل الاستخدام.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'يتطلب Godot 4.x ومضيفاً محلياً متوافقاً مع MCP؛ تحقق من متطلبات نظام التشغيل.',
    ),
    NovaGameTool(
      id: 'blender-mcp',
      name: 'Blender MCP',
      kind: NovaGameToolKind.aiBridge,
      repository: 'https://github.com/ahujasid/mcp-for-blender',
      purpose: 'ربط مساعد الذكاء الاصطناعي بـ Blender لأتمتة عمليات النمذجة والمشهد.',
      licenseNote: 'MIT حسب بيانات المشروع؛ تحقق من الترخيص الحالي والاعتماديات.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'يحتاج Blender ومضيف MCP ومساعداً متوافقاً.',
    ),
    NovaGameTool(
      id: 'terrain3d',
      name: 'Terrain3D',
      kind: NovaGameToolKind.terrain,
      repository: 'https://github.com/TokisanGames/Terrain3D',
      purpose: 'إنشاء وتحرير تضاريس واسعة للعوالم المفتوحة في Godot.',
      licenseNote: 'مفتوح المصدر؛ افحص الترخيص الخاص بالإصدار قبل التوزيع.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'توافقه مرتبط بإصدار Godot والمنصة المستهدفة.',
    ),
    NovaGameTool(
      id: 'godot-jolt',
      name: 'Godot Jolt',
      kind: NovaGameToolKind.physics,
      repository: 'https://github.com/godot-jolt/godot-jolt',
      purpose: 'محرك فيزياء ثلاثي الأبعاد بديل لمشاريع Godot عند الحاجة.',
      licenseNote: 'مفتوح المصدر؛ افحص الترخيص والإصدار.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'تحقق أولاً من فيزياء Jolt المدمجة في إصدار Godot المستخدم.',
    ),
    NovaGameTool(
      id: 'limboai',
      name: 'LimboAI',
      kind: NovaGameToolKind.npcAi,
      repository: 'https://github.com/limbonaut/limboai',
      purpose: 'أشجار سلوك وآلات حالات لسلوك الأعداء والشخصيات غير القابلة للعب.',
      licenseNote: 'MIT حسب بيانات المشروع؛ تحقق من الإصدار المستخدم.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'ذكاء سلوكي داخل اللعبة، وليس نموذجاً لغوياً مستضافاً.',
    ),
    NovaGameTool(
      id: 'dialogic',
      name: 'Dialogic',
      kind: NovaGameToolKind.dialogue,
      repository: 'https://github.com/dialogic-godot/dialogic',
      purpose: 'إنشاء حوارات ومشاهد قصصية واختيارات متفرعة.',
      licenseNote: 'مفتوح المصدر؛ راجع الترخيص والإصدار.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'يجب اختيار إصدار متوافق مع Godot.',
    ),
    NovaGameTool(
      id: 'phantom-camera',
      name: 'Phantom Camera',
      kind: NovaGameToolKind.camera,
      repository: 'https://github.com/ramokz/phantom-camera',
      purpose: 'أنظمة كاميرا وتتبع وانتقالات سينمائية لألعاب Godot.',
      licenseNote: 'مفتوح المصدر؛ راجع الترخيص والإصدار.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'تأكد من دعم نسخة Godot المستهدفة قبل إضافتها.',
    ),
    NovaGameTool(
      id: 'meshoptimizer',
      name: 'meshoptimizer',
      kind: NovaGameToolKind.optimization,
      repository: 'https://github.com/zeux/meshoptimizer',
      purpose: 'تحسين بيانات الشبكات الهندسية وتقليل كلفة الأصول ثلاثية الأبعاد.',
      licenseNote: 'MIT.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'مكتبة؛ تحتاج خط معالجة وربطاً مناسباً لتعمل داخل المحرك.',
    ),
    NovaGameTool(
      id: 'godot-demo-projects',
      name: 'Godot Demo Projects',
      kind: NovaGameToolKind.examples,
      repository: 'https://github.com/godotengine/godot-demo-projects',
      purpose: 'أمثلة رسمية قابلة للدراسة كنماذج للمشاهد والحركة والفيزياء وواجهات اللعب.',
      licenseNote: 'راجع ترخيص كل مشروع وأصل ضمن المستودع.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'اختَر مثالاً مطابقاً لإصدار Godot ثم شغّله واختبره قبل إعادة استخدامه.',
    ),
    NovaGameTool(
      id: 'phaser',
      name: 'Phaser',
      kind: NovaGameToolKind.webEngine,
      repository: 'https://github.com/phaserjs/phaser',
      purpose: 'محرك JavaScript لصنع ألعاب 2D للويب؛ خيار إضافي للألعاب التي تعمل في المتصفح.',
      licenseNote: 'MIT.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'مسار منفصل عن مشروع Godot؛ يحتاج Node.js وأدوات ويب عند البناء.',
    ),
    NovaGameTool(
      id: 'bevy',
      name: 'Bevy Engine',
      kind: NovaGameToolKind.engine,
      repository: 'https://github.com/bevyengine/bevy',
      purpose: 'محرك ألعاب مفتوح المصدر مبني على Rust ونظام ECS.',
      licenseNote: 'MIT أو Apache-2.0 وفق الترخيص المرفق.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'بديل لمحرك Godot وليس إضافة له؛ يتطلب Rust وبيئة بناء متوافقة.',
    ),
    NovaGameTool(
      id: 'defold',
      name: 'Defold',
      kind: NovaGameToolKind.engine,
      repository: 'https://github.com/defold/defold',
      purpose: 'محرك مستقل لألعاب 2D مع تصدير لمنصات مدعومة.',
      licenseNote: 'راجع ترخيص المحرك والمكونات قبل التوزيع.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'بديل مستقل عن Godot؛ تحقق من متطلبات التصدير لكل منصة.',
    ),
    NovaGameTool(
      id: 'gdevelop',
      name: 'GDevelop',
      kind: NovaGameToolKind.engine,
      repository: 'https://github.com/4ian/GDevelop',
      purpose: 'منصة تطوير ألعاب بأحداث مرئية لتقليل الحاجة لكتابة الشيفرة يدوياً.',
      licenseNote: 'المستودع مفتوح المصدر؛ راجع شروط الخدمات والميزات المستضافة منفصلة.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'مسار بناء مستقل؛ بعض الخدمات أو التصدير قد تعتمد على شروطها الخاصة.',
    ),
    NovaGameTool(
      id: 'pixelorama',
      name: 'Pixelorama',
      kind: NovaGameToolKind.pixelArt,
      repository: 'https://github.com/Orama-Interactive/Pixelorama',
      purpose: 'رسم بكسل آرت وتحريك sprites للشخصيات والعناصر ثنائية الأبعاد.',
      licenseNote: 'مفتوح المصدر؛ راجع الترخيص الحالي.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'أداة أصول منفصلة؛ يلزم تصدير الصور واستيرادها إلى المحرك.',
    ),
    NovaGameTool(
      id: 'material-maker',
      name: 'Material Maker',
      kind: NovaGameToolKind.materials,
      repository: 'https://github.com/RodZill4/material-maker',
      purpose: 'إنشاء خامات ومواد إجرائية للألعاب والمشاهد ثلاثية الأبعاد.',
      licenseNote: 'مفتوح المصدر؛ راجع الترخيص الحالي.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'يحتاج بيئة تشغيل متوافقة ثم تصدير المواد بصيغة يدعمها المحرك.',
    ),
    NovaGameTool(
      id: 'libresprite',
      name: 'LibreSprite',
      kind: NovaGameToolKind.pixelArt,
      repository: 'https://github.com/LibreSprite/LibreSprite',
      purpose: 'أداة مفتوحة المصدر لرسم وتحريك pixel art وتصدير spritesheets.',
      licenseNote: 'راجع الترخيص المرفق بالإصدار والمكونات.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'أداة منفصلة؛ لم تُربط بعد بمولّد الأصول داخل NOVA.',
    ),
    NovaGameTool(
      id: 'lmms',
      name: 'LMMS',
      kind: NovaGameToolKind.audio,
      repository: 'https://github.com/LMMS/lmms',
      purpose: 'إنشاء موسيقى ومقاطع صوتية يمكن تجهيزها كأصول للعبة.',
      licenseNote: 'GPL؛ مجاني ومفتوح المصدر.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'مسار إنتاج صوت منفصل؛ تحقق من تراخيص العينات والمكتبات التي تستخدمها.',
    ),
    NovaGameTool(
      id: 'trenchbroom',
      name: 'TrenchBroom',
      kind: NovaGameToolKind.terrain,
      repository: 'https://github.com/TrenchBroom/TrenchBroom',
      purpose: 'محرر خرائط ومراحل ثلاثية الأبعاد مناسب لبعض خطوط عمل ألعاب Quake-like.',
      licenseNote: 'مفتوح المصدر؛ راجع الترخيص الحالي.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'ليس محرر Godot عامّاً؛ يحتاج خط استيراد/تحويل متوافقاً مع نوع اللعبة.',
    ),
  ];

  static List<NovaGameTool> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return tools;
    return tools.where((tool) =>
      tool.name.toLowerCase().contains(q) ||
      tool.id.contains(q) ||
      tool.purpose.toLowerCase().contains(q) ||
      tool.kind.name.toLowerCase().contains(q)
    ).toList(growable: false);
  }
}
