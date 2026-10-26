/// Curated free/open-source game-development toolkit for NOVA.

/// These entries are a discoverable catalogue, NOT claims that the tools are
/// installed or connected. Runtime integration requires a compatible desktop/

/// build host, explicit setup, licence checks, and automated verification.
library;

enum NovaGameToolKind { engine, art, aiBridge, terrain, physics, npcAi, dialogue, camera, optimization }

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
      compatibilityNote: 'ليس مولّد مجسمات سحابياً مستقلاً؛ يحتاج Blender ومضيف MCP ومساعداً متوافقاً.',
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
      compatibilityNote: 'Godot 4.4 وما بعده يتضمن تكاملاً مع Jolt؛ لا تضف الإضافة منفصلة دون فحص الحاجة والتوافق.',
    ),
    NovaGameTool(
      id: 'limboai',
      name: 'LimboAI',
      kind: NovaGameToolKind.npcAi,
      repository: 'https://github.com/limbonaut/limboai',
      purpose: 'أشجار سلوك وآلات حالات لسلوك الأعداء والشخصيات غير القابلة للعب.',
      licenseNote: 'MIT حسب بيانات المشروع؛ تحقق من الإصدار المستخدم.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'ذكاء سلوكي داخل اللعبة، وليس نموذجاً لغوياً أو خدمة AI مستضافة.',
    ),
    NovaGameTool(
      id: 'dialogic',
      name: 'Dialogic',
      kind: NovaGameToolKind.dialogue,
      repository: 'https://github.com/dialogic-godot/dialogic',
      purpose: 'إنشاء حوارات ومشاهد قصصية واختيارات متفرعة.',
      licenseNote: 'مفتوح المصدر؛ راجع الترخيص والإصدار.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'يجب اختيار إصدار متوافق مع إصدار Godot للمشروع.',
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
      purpose: 'تحسين وترتيب بيانات الشبكات الهندسية وتقليل كلفة الأصول ثلاثية الأبعاد.',
      licenseNote: 'MIT.',
      integrationStatus: statusCatalogOnly,
      compatibilityNote: 'مكتبة أدوات/خوارزميات؛ ليست زر تحسين تلقائياً داخل Godot دون بناء خط معالجة وربط مناسب.',
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
