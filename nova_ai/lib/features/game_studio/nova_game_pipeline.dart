import 'nova_game_tool_catalog.dart';

enum NovaGameStageStatus { readyToGenerate, needsRunner, optionalTooling }

class NovaGamePipelineStage {
  const NovaGamePipelineStage({
    required this.id,
    required this.title,
    required this.description,
    required this.toolIds,
    required this.status,
    required this.completionGate,
  });

  final String id;
  final String title;
  final String description;
  final List<String> toolIds;
  final NovaGameStageStatus status;
  final String completionGate;

  List<NovaGameTool> get tools => NovaGameToolCatalog.tools
      .where((tool) => toolIds.contains(tool.id))
      .toList(growable: false);
}

/// Describes the orchestration plan NOVA can follow. It deliberately does not
/// claim to launch tools: the runner and MCP integrations must be configured
/// and validated before any stage can be marked as executed.
class NovaGamePipeline {
  NovaGamePipeline._();

  static const stages = <NovaGamePipelineStage>[
    NovaGamePipelineStage(
      id: 'plan',
      title: '1. الفكرة وخطة اللعبة',
      description: 'تحديد النوع والمنصة وآلية اللعب والمراحل ومعايير النجاح.',
      toolIds: ['godot-engine', 'godot-demo-projects'],
      status: NovaGameStageStatus.readyToGenerate,
      completionGate: 'حفظ مواصفات اللعبة ومراجعتها قبل إنشاء الملفات.',
    ),
    NovaGamePipelineStage(
      id: 'prototype',
      title: '2. إنشاء النموذج الأولي',
      description: 'إنشاء ملفات المشروع والمشهد والسكربتات الأساسية.',
      toolIds: ['godot-engine', 'phaser', 'gdevelop'],
      status: NovaGameStageStatus.readyToGenerate,
      completionGate: 'إنشاء الملفات والتحقق من وجودها وصحة البنية.',
    ),
    NovaGamePipelineStage(
      id: 'assets',
      title: '3. الرسومات والمجسمات والخامات',
      description: 'إنتاج أو استيراد أصول مرخصة، ثم ربطها بالمشروع.',
      toolIds: ['blender', 'blender-mcp', 'pixelorama', 'libresprite', 'material-maker'],
      status: NovaGameStageStatus.optionalTooling,
      completionGate: 'فحص ملفات الأصول والترخيص وصيغ الاستيراد.',
    ),
    NovaGamePipelineStage(
      id: 'world',
      title: '4. العالم والكاميرا والفيزياء',
      description: 'تجهيز التضاريس والتصادم والكاميرا وتحسين الأصول عند الحاجة.',
      toolIds: ['terrain3d', 'godot-jolt', 'phantom-camera', 'meshoptimizer', 'trenchbroom'],
      status: NovaGameStageStatus.optionalTooling,
      completionGate: 'فتح المشهد بالمحرك المستهدف والتحقق من التصادم والأداء.',
    ),
    NovaGamePipelineStage(
      id: 'gameplay',
      title: '5. الأعداء والحوارات والصوت',
      description: 'إضافة سلوك الشخصيات والحوارات والموسيقى حسب نوع اللعبة.',
      toolIds: ['limboai', 'dialogic', 'lmms'],
      status: NovaGameStageStatus.optionalTooling,
      completionGate: 'اختبارات سلوك قابلة للتكرار ومراجعة تراخيص الصوت.',
    ),
    NovaGamePipelineStage(
      id: 'automated-qa',
      title: '6. التشغيل والاختبار والإصلاح',
      description: 'تسليم المشروع إلى مضيف بناء آمن لتشغيل المحرك وجمع الأخطاء وإعادة الاختبار.',
      toolIds: ['godot-ai-workbench'],
      status: NovaGameStageStatus.needsRunner,
      completionGate: 'مضيف Godot/MCP متصل ومصرح به، مع سجلات اختبار ناجحة.',
    ),
    NovaGamePipelineStage(
      id: 'alternative-engine',
      title: 'مسار بديل: محرك مستقل',
      description: 'اختيار محرك بديل فقط إذا كانت اللعبة تتطلبه؛ لا تخلط مشاريع المحركات المختلفة.',
      toolIds: ['bevy', 'defold'],
      status: NovaGameStageStatus.optionalTooling,
      completionGate: 'تثبيت toolchain المناسب واختيار محرك واحد للمشروع.',
    ),
  ];

  static NovaGamePipelineStage? stageById(String id) {
    for (final stage in stages) {
      if (stage.id == id) return stage;
    }
    return null;
  }
}
