import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/integrations/nova_tool_catalog.dart';

void main() {
  group('NOVA tool catalog', () {
    test('contains exactly 50 tools with unique IDs and names', () {
      expect(novaToolCatalog, hasLength(50));
      expect(novaToolCatalog.map((tool) => tool.id).toSet(), hasLength(50));
      expect(novaToolCatalog.map((tool) => tool.name).toSet(), hasLength(50));
    });

    test('every catalog entry has a valid HTTPS resource link and category', () {
      for (final tool in novaToolCatalog) {
        final uri = Uri.parse(tool.url);
        expect(uri.scheme, 'https', reason: tool.name);
        expect(uri.host, isNotEmpty, reason: tool.name);
        expect(tool.category, isNotEmpty, reason: tool.name);
        expect(tool.description, isNotEmpty, reason: tool.name);
      }
    });
  });
}
