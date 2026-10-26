import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/opportunities/global_opportunity_radar.dart';

void main() {
  group('Global opportunity radar search', () {
    test('contains global starter catalogue and official links', () {
      expect(globalOpportunityCatalogue.length, greaterThanOrEqualTo(10));
      expect(globalOpportunityCatalogue.every((item) => item.url.startsWith('https://')), isTrue);
    });

    test('matches Arabic, English and non-Latin language terms', () {
      expect(searchGlobalOpportunities(query: 'ترجمة').any((item) => item.id == 'proz'), isTrue);
      expect(searchGlobalOpportunities(query: 'remote job').any((item) => item.id == 'wellfound'), isTrue);
      expect(searchGlobalOpportunities(query: '翻译').any((item) => item.id == 'proz'), isTrue);
      expect(searchGlobalOpportunities(query: 'डेटा लेबलिंग').any((item) => item.id == 'oneforma'), isTrue);
    });

    test('filters categories and saved opportunities', () {
      final filtered = searchGlobalOpportunities(category: 'برمجة ومكافآت');
      expect(filtered, isNotEmpty);
      expect(filtered.every((item) => item.category == 'برمجة ومكافآت'), isTrue);

      final saved = searchGlobalOpportunities(savedIds: const ['telus-ai'], savedOnly: true);
      expect(saved.map((item) => item.id), ['telus-ai']);
    });

    test('normalizes Arabic diacritics and alef variants', () {
      expect(normalizeRadarText('إِلى أَين؟'), 'الي اين');
    });
  });
}
