import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/game_studio/nova_game_tool_catalog.dart';

void main() {
  group('NovaGameToolCatalog', () {
    test('contains ten unique curated repositories and labels integrations honestly', () {
      final tools = NovaGameToolCatalog.tools;
      expect(tools, hasLength(10));
      expect(tools.map((tool) => tool.id).toSet(), hasLength(10));
      expect(tools.map((tool) => tool.repository).toSet(), hasLength(10));
      expect(tools.every((tool) => tool.repository.startsWith('https://github.com/')), isTrue);
      expect(tools.every((tool) => tool.integrationStatus == NovaGameToolCatalog.statusCatalogOnly), isTrue);
    });

    test('search filters by name and purpose and returns all for blank query', () {
      expect(NovaGameToolCatalog.search('').length, 10);
      expect(NovaGameToolCatalog.search('Blender').map((tool) => tool.id),
          containsAll(<String>['blender', 'blender-mcp']));
      expect(NovaGameToolCatalog.search('dialogue').single.id, 'dialogic');
      expect(NovaGameToolCatalog.search('no-such-tool'), isEmpty);
    });
  });
}
