import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/research/research_connector.dart';

void main() {
  group('ResearchQuery', () {
    test('trims query and preserves selected options', () {
      final query = const ResearchQuery(
        text: '  remote jobs Sudan  ',
        language: 'en',
        maxResults: 5,
      ).normalized();

      expect(query.text, 'remote jobs Sudan');
      expect(query.language, 'en');
      expect(query.maxResults, 5);
    });

    test('rejects empty and excessively long queries', () {
      expect(() => const ResearchQuery(text: '  ').normalized(), throwsArgumentError);
      expect(
        () => ResearchQuery(text: List.filled(501, 'x').join()).normalized(),
        throwsArgumentError,
      );
    });

    test('bounds requested result count', () {
      expect(
        () => const ResearchQuery(text: 'jobs', maxResults: 0).normalized(),
        throwsArgumentError,
      );
      expect(
        () => const ResearchQuery(text: 'jobs', maxResults: 26).normalized(),
        throwsArgumentError,
      );
    });
  });

  group('ResearchResult safety', () {
    test('accepts HTTPS and rejects insecure or credential-bearing URLs', () {
      expect(
        const ResearchResult(
          title: 'Source',
          url: 'https://example.com/a',
          sourceId: 'web',
        ).isUsable,
        isTrue,
      );
      expect(
        const ResearchResult(
          title: 'Source',
          url: 'http://example.com',
          sourceId: 'web',
        ).isUsable,
        isFalse,
      );
      expect(
        const ResearchResult(
          title: 'Source',
          url: 'https://user:pass@example.com',
          sourceId: 'web',
        ).isUsable,
        isFalse,
      );
    });
  });

  group('normalizeResearchResults', () {
    test('drops unsafe results, deduplicates URLs and caps output', () {
      final results = normalizeResearchResults([
        const ResearchResult(
          title: 'First',
          url: 'https://example.com/a?x=1',
          sourceId: 'reader',
        ),
        const ResearchResult(
          title: 'Duplicate',
          url: 'https://example.com/a?x=2',
          sourceId: 'reader',
        ),
        const ResearchResult(
          title: 'Insecure',
          url: 'http://example.org',
          sourceId: 'reader',
        ),
        const ResearchResult(
          title: 'Second',
          url: 'https://example.org',
          sourceId: 'search',
        ),
        const ResearchResult(
          title: 'Third',
          url: 'https://example.net',
          sourceId: 'search',
        ),
      ], maxResults: 2);

      expect(results.map((item) => item.title), ['First', 'Second']);
      expect(
        () => results.add(const ResearchResult(
          title: 'No',
          url: 'https://no.example',
          sourceId: 'test',
        )),
        throwsUnsupportedError,
      );
    });

    test('drops blank titles and blank source identifiers', () {
      final results = normalizeResearchResults([
        const ResearchResult(
          title: ' ',
          url: 'https://example.com',
          sourceId: 'reader',
        ),
        const ResearchResult(
          title: 'No source',
          url: 'https://example.org',
          sourceId: ' ',
        ),
      ]);
      expect(results, isEmpty);
    });
  });
}
