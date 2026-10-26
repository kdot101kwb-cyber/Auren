import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/game_studio/nova_game_build_coordinator.dart';
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

  test('canonical ten-tool build chain is connected across ordered stages', () {
    final chain = NovaGameBuildCoordinator.defaultToolChain;
    final plan = NovaGameBuildCoordinator.createPlan('A 2D exploration game');

    expect(chain, hasLength(10));
    expect(chain.toSet(), hasLength(10));
    expect(plan.connectedToolIds, containsAll(chain));
    for (final id in chain) {
      expect(
        NovaGameToolCatalog.tools.any((tool) => tool.id == id),
        isTrue,
        reason: 'Missing catalogue entry for $id',
      );
    }
    final pipelineIds =
        NovaGamePipeline.stages.expand((stage) => stage.toolIds).toSet();
    expect(pipelineIds, containsAll(chain));
  });

  test('Godot execution is explicitly gated on a configured runner', () {
    final qa = NovaGamePipeline.stageById('automated-qa');
    expect(qa, isNotNull);
    expect(qa!.status, NovaGameStageStatus.needsRunner);
    expect(qa.completionGate, contains('مضيف Godot/MCP متصل'));
    expect(
      NovaGameToolCatalog.tools.every(
        (tool) => tool.integrationStatus == NovaGameToolCatalog.statusCatalogOnly,
      ),
      isTrue,
    );
  });
}
