import 'nova_game_pipeline.dart';
import 'nova_game_tool_catalog.dart';

/// Builds one explicit, ordered work plan that maps a game idea to the
/// selected free-tool chain. This plans and packages work; it does not claim
/// to launch external engines or MCP servers.
class NovaGameBuildTask {
  const NovaGameBuildTask({
    required this.order,
    required this.stageId,
    required this.title,
    required this.goal,
    required this.toolIds,
    required this.acceptanceCheck,
    required this.requiresExternalRunner,
  });

  final int order;
  final String stageId;
  final String title;
  final String goal;
  final List<String> toolIds;
  final String acceptanceCheck;
  final bool requiresExternalRunner;

  List<NovaGameTool> get tools => NovaGameToolCatalog.tools
      .where((tool) => toolIds.contains(tool.id))
      .toList(growable: false);

  Map<String, Object?> toJson() => {
        'order': order,
        'stage_id': stageId,
        'title': title,
        'goal': goal,
        'tool_ids': toolIds,
        'tools': tools
            .map((tool) => {
                  'id': tool.id,
                  'name': tool.name,
                  'repository': tool.repository,
                  'integration_status': tool.integrationStatus,
                })
            .toList(),
        'acceptance_check': acceptanceCheck,
        'requires_external_runner': requiresExternalRunner,
        'execution_status': 'planned_not_executed',
      };
}

class NovaGameBuildPlan {
  const NovaGameBuildPlan({
    required this.idea,
    required this.engine,
    required this.tasks,
  });

  final String idea;
  final String engine;
  final List<NovaGameBuildTask> tasks;

  List<String> get connectedToolIds => tasks
      .expand((task) => task.toolIds)
      .toSet()
      .toList(growable: false);

  Map<String, Object?> toJson() => {
        'schema_version': 1,
        'created_by': 'NOVA Game Studio',
        'idea': idea,
        'selected_engine': engine,
        'execution_status': 'planned_not_executed',
        'tool_chain': connectedToolIds,
        'tasks': tasks.map((task) => task.toJson()).toList(),
        'safety': {
          'network_access': 'not_started',
          'external_actions': 'require_user_approval',
          'budget_usd': 0,
          'note':
              'Repositories are references only until a compatible runner explicitly installs and verifies them.',
        },
      };
}

class NovaGameBuildCoordinator {
  NovaGameBuildCoordinator._();

  /// The ten-tool default chain: engine, AI bridge, assets, terrain, physics,
  /// NPC behavior, dialogue, camera, optimization, and sample projects.
  static const defaultToolChain = <String>[
    'godot-engine',
    'godot-ai-workbench',
    'blender',
    'blender-mcp',
    'terrain3d',
    'godot-jolt',
    'limboai',
    'dialogic',
    'phantom-camera',
    'meshoptimizer',
  ];

  static NovaGameBuildPlan createPlan(String rawIdea) {
    final idea = rawIdea.trim();
    if (idea.isEmpty) {
      throw ArgumentError.value(rawIdea, 'rawIdea', 'Game idea cannot be empty');
    }
    final selectedTools = defaultToolChain
        .where((id) => NovaGameToolCatalog.tools.any((tool) => tool.id == id))
        .toList(growable: false);

    final stages = <NovaGameBuildTask>[
      NovaGameBuildTask(
        order: 1,
        stageId: 'design',
        title: 'تحليل الفكرة وتصميم اللعبة',
        goal: 'تحويل الفكرة إلى حلقة لعب، مراحل، تحكم، وشروط نجاح واضحة.',
        toolIds: const ['godot-engine'],
        acceptanceCheck: 'خطة اللعبة مكتوبة ولا تحتوي متطلبات متناقضة.',
        requiresExternalRunner: false,
      ),
      NovaGameBuildTask(
        order: 2,
        stageId: 'prototype',
        title: 'إنشاء المشروع والنموذج الأولي',
        goal: 'تجهيز هيكل Godot 4 ومشهد البداية وسكربتات اللعب.',
        toolIds: const ['godot-engine', 'godot-ai-workbench'],
        acceptanceCheck: 'ملفات المشروع والمشهد والسكربت موجودة.',
        requiresExternalRunner: true,
      ),
      NovaGameBuildTask(
        order: 3,
        stageId: 'art-assets',
        title: 'إنتاج الأصول وربطها',
        goal: 'تخطيط الشخصيات والمجسمات والخامات ثم استيرادها.',
        toolIds: const ['blender', 'blender-mcp'],
        acceptanceCheck: 'الأصول موجودة وتراخيصها وصيغها موثقة.',
        requiresExternalRunner: true,
      ),
      NovaGameBuildTask(
        order: 4,
        stageId: 'world-physics',
        title: 'بناء العالم والفيزياء والكاميرا',
        goal: 'إضافة التضاريس والتصادم والكاميرا وتحسين الشبكات عند الحاجة.',
        toolIds: const [
          'terrain3d',
          'godot-jolt',
          'phantom-camera',
          'meshoptimizer',
        ],
        acceptanceCheck: 'المشهد يفتح دون أخطاء وتُراجع التصادمات والأداء.',
        requiresExternalRunner: true,
      ),
      NovaGameBuildTask(
        order: 5,
        stageId: 'behavior-story',
        title: 'إضافة سلوك الشخصيات والحوارات',
        goal: 'إعداد سلوك الأعداء والشخصيات والحوارات حسب نوع اللعبة.',
        toolIds: const ['limboai', 'dialogic'],
        acceptanceCheck: 'توجد حالات اختبار لسلوك الشخصيات والحوارات.',
        requiresExternalRunner: true,
      ),
      NovaGameBuildTask(
        order: 6,
        stageId: 'qa-export',
        title: 'الاختبار والإصلاح ثم التجهيز للتصدير',
        goal: 'تشغيل المشروع في بيئة Godot موثوقة، جمع السجلات وإعادة الاختبار.',
        toolIds: const ['godot-engine', 'godot-ai-workbench'],
        acceptanceCheck: 'اختبارات المحرك ناجحة وسجل الأخطاء فارغ قبل طلب التصدير.',
        requiresExternalRunner: true,
      ),
    ];

    // Fail closed if an id drifts out of the catalogue: don't silently produce
    // a plan that references tools NOVA cannot link to.
    for (final id in selectedTools) {
      if (!NovaGameToolCatalog.tools.any((tool) => tool.id == id)) {
        throw StateError('Unknown game tool: $id');
      }
    }
    return NovaGameBuildPlan(
      idea: idea,
      engine: 'Godot 4',
      tasks: stages,
    );
  }
}
