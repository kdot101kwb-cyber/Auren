import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/game_studio/nova_game_pipeline.dart';
import 'package:nova_ai/features/game_studio/nova_game_tool_catalog.dart';

void main() {
  group('NovaGameToolCatalog', () {
    test('contains twenty unique repositories and labels integrations honestly', () {
      final tools = NovaGameToolCatalog.tools;
      expect(tools, hasLength(20));
      expect(tools.map((tool) => tool.id).toSet(), hasLength(20));
      expect(tools.map((tool) => tool.repository).toSet(), hasLength(20));
      expect(tools.every((tool) => tool.repository.startsWith('https://github.com/')), isTrue);
      expect(tools.every((tool) => tool.integrationStatus == NovaGameToolCatalog.statusCatalogOnly), isTrue);
    });

    test('search filters by name and purpose and returns all for blank query', () {
      expect(NovaGameToolCatalog.search('').length, 20);
      expect(NovaGameToolCatalog.search('Blender').map((tool) => tool.id),
          containsAll(<String>['blender', 'blender-mcp']));
      expect(NovaGameToolCatalog.search('dialogue').single.id, 'dialogic');
      expect(NovaGameToolCatalog.search('no-such-tool'), isEmpty);
    });
  });

  group('NovaGamePipeline', () {
    test('pipeline stages reference existing tools and declare completion gates', () {
      for (final stage in NovaGamePipeline.stages) {
        expect(stage.toolIds, isNotEmpty);
        expect(stage.tools, isNotEmpty, reason: stage.id);
        expect(stage.completionGate, isNotEmpty);
      }
      expect(NovaGamePipeline.stageById('automated-qa')?.status,
          NovaGameStageStatus.needsRunner);
      expect(NovaGamePipeline.stageById('unknown'), isNull);
    });
  });
}
