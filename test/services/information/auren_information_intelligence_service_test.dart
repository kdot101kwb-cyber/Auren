import 'package:flutter_test/flutter_test.dart';

import 'package:auren/services/information/auren_information_intelligence_service.dart';

void main() {
  group('Citation Export Studio', () {
    const record = CitationRecord(
      author: 'Ada Lovelace',
      title: 'Computing Notes',
      year: '1843',
      publisher: 'Example Press',
      url: 'https://example.org/notes',
    );

    test('formats APA, BibTeX, and RIS output', () {
      expect(
        CitationExportStudio.format(record, CitationStyle.apa7),
        'Ada Lovelace. (1843). Computing Notes. Example Press. https://example.org/notes',
      );
      expect(CitationExportStudio.format(record, CitationStyle.bibtex), contains('@misc{lovelace1843,'));
      final ris = CitationExportStudio.format(record, CitationStyle.ris);
      expect(ris, contains('TY  - GEN'));
      expect(ris, contains('TI  - Computing Notes'));
      expect(ris, endsWith('ER  -'));
    });

    test('rejects unsafe source URLs and missing titles', () {
      expect(
        () => CitationExportStudio.format(
          const CitationRecord(title: 'Unsafe', url: 'javascript:alert(1)'),
          CitationStyle.apa7,
        ),
        throwsArgumentError,
      );
      expect(
        () => CitationExportStudio.format(const CitationRecord(title: ' ', url: ''), CitationStyle.apa7),
        throwsArgumentError,
      );
    });
  });

  test('Topic Watchlist matches distinct topics case-insensitively', () {
    final matches = TopicWatchlistEngine.match(
      topics: ['Sudan', 'climate', ' sudan ', ''],
      items: const [
        InformationItem(id: '1', title: 'Sudan update', summary: 'Regional report'),
        InformationItem(id: '2', title: 'Climate outlook', summary: 'Global forecast'),
        InformationItem(id: '3', title: 'Sports results'),
      ],
    );
    expect(matches.map((match) => match.item.id), ['1', '2']);
    expect(matches.first.matchedTopics, ['Sudan']);
  });

  group('Source Freshness Radar', () {
    final now = DateTime.utc(2026, 10, 20, 12);

    test('classifies unknown, fresh, review-soon, and stale sources', () {
      expect(SourceFreshnessRadar.assess(lastCheckedAt: null, now: now).status, SourceFreshnessStatus.unknown);
      expect(
        SourceFreshnessRadar.assess(lastCheckedAt: now.subtract(const Duration(days: 2)), now: now).status,
        SourceFreshnessStatus.fresh,
      );
      expect(
        SourceFreshnessRadar.assess(lastCheckedAt: now.subtract(const Duration(days: 14)), now: now).status,
        SourceFreshnessStatus.reviewSoon,
      );
      expect(
        SourceFreshnessRadar.assess(lastCheckedAt: now.subtract(const Duration(days: 45)), now: now).status,
        SourceFreshnessStatus.stale,
      );
    });

    test('rejects inverted freshness thresholds', () {
      expect(
        () => SourceFreshnessRadar.assess(lastCheckedAt: now, now: now, freshForDays: 20, staleAfterDays: 10),
        throwsArgumentError,
      );
    });
  });

  group('Offline Knowledge Pack Planner', () {
    final now = DateTime.utc(2026, 10, 20);
    const items = [
      KnowledgePackItem(id: 'note-1', title: 'Water safety', body: 'Keep clean water covered.', sourceUrl: 'https://example.org/water'),
      KnowledgePackItem(id: 'note-2', title: 'Emergency contacts'),
    ];

    test('builds a bounded, exportable manifest', () {
      final manifest = OfflineKnowledgePackPlanner.build(items: items, now: now);
      expect(manifest.items.length, 2);
      expect(manifest.estimatedBytes, greaterThan(0));
      expect(manifest.toJson()['schemaVersion'], 1);
      expect(manifest.encode(), contains('"itemCount": 2'));
    });

    test('rejects empty, duplicate, unsafe, and oversized packs', () {
      expect(() => OfflineKnowledgePackPlanner.build(items: const [], now: now), throwsArgumentError);
      expect(
        () => OfflineKnowledgePackPlanner.build(
          items: const [KnowledgePackItem(id: 'same', title: 'A'), KnowledgePackItem(id: 'same', title: 'B')],
          now: now,
        ),
        throwsArgumentError,
      );
      expect(
        () => OfflineKnowledgePackPlanner.build(
          items: const [KnowledgePackItem(id: 'bad', title: 'A', sourceUrl: 'file:///tmp/a')],
          now: now,
        ),
        throwsArgumentError,
      );
      expect(
        () => OfflineKnowledgePackPlanner.build(
          items: const [KnowledgePackItem(id: 'big', title: 'A', body: '0123456789')],
          now: now,
          maxEstimatedBytes: 5,
        ),
        throwsArgumentError,
      );
    });
  });

  test('Knowledge Revision Ledger reports additions and removals', () {
    final diff = KnowledgeRevisionLedger.compare('Title\nOld source\nKeep this', 'Title\nNew source\nKeep this');
    expect(diff.hasChanges, isTrue);
    expect(diff.addedLines, ['New source']);
    expect(diff.removedLines, ['Old source']);
    expect(KnowledgeRevisionLedger.compare('Same\nText', 'Same\nText').hasChanges, isFalse);
  });
}
