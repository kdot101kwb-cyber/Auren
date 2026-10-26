import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/game_studio/nova_game_pipeline.dart';
import 'package:nova_ai/features/game_studio/nova_game_tool_catalog.dart';

void main() {
  test('all pipeline stages reference existing catalogue entries', () {
    expect(NovaGamePipeline.stages, isNotEmpty);
    for (final stage in NovaGamePipeline.stages) {
      expect(stage.toolIds, isNotEmpty, reason: stage.id);
      expect(stage.tools.map((tool) => tool.id).toSet(), stage.toolIds.toSet(),
          reason: 'Pipeline stage ${stage.id} has an unknown or missing tool');
    }
  });

  test('ten-tool build chain is connected across ordered build stages', () {
    final chain = NovaGameBuildChainForTest.toolIds;
    expect(chain, hasLength(10));
    expect(chain.toSet(), hasLength(10));
    for (final id in chain) {
      expect(
        NovaGameToolCatalog.tools.any((tool) => tool.id == id),
        isTrue,
        reason: 'Missing catalogue entry for $id',
      );
    }
    final stageIds = NovaGamePipeline.stages.expand((stage) => stage.toolIds).toSet();
    expect(stageIds, containsAll(chain));
  });

  test('Godot execution is explicitly gated on a configured runner', () {
    final qa = NovaGamePipeline.stageById('automated-qa');
    expect(qa, isNotNull);
    expect(qa!.status, NovaGameStageStatus.needsRunner);
    expect(qa.completionGate, contains('مضيف Godot/MCP متصل'));
    expect(NovaGameToolCatalog.tools.every(
      (tool) => tool.integrationStatus == NovaGameToolCatalog.statusCatalogOnly,
    ), isTrue);
  });
}

/// Mirrors the documented default chain without depending on UI code.
class NovaGameBuildChainForTest {
  static const toolIds = <String>[
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
}
