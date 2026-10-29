import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/research/research_connector.dart';
import 'package:nova_ai/features/research/research_service.dart';

class _FakeConnector implements ResearchConnector {
  _FakeConnector(this.id, this.handler);

  @override
  final String id;

  final Future<List<ResearchResult>> Function(ResearchQuery query) handler;

  @override
  Future<List<ResearchResult>> search(ResearchQuery query) => handler(query);
}

void main() {
  group('ResearchService', () {
    test('aggregates sources, removes duplicate URLs, and respects result cap', () async {
      final service = ResearchService(connectors: [
        _FakeConnector('first', (query) async => [
          const ResearchResult(
            title: 'First result',
            url: 'https://example.com/item?source=first',
            sourceId: 'first',
          ),
          const ResearchResult(
            title: 'Unsafe result',
            url: 'http://unsafe.example/item',
            sourceId: 'first',
          ),
        ]),
        _FakeConnector('second', (query) async => [
          const ResearchResult(
            title: 'Duplicate result',
            url: 'https://example.com/item?source=second',
            sourceId: 'second',
          ),
          const ResearchResult(
            title: 'Second result',
            url: 'https://example.org/item',
            sourceId: 'second',
          ),
        ]),
      ]);

      final report = await service.search(
        const ResearchQuery(text: '  remote work  ', maxResults: 2),
      );

      expect(report.results.map((item) => item.title),
          ['First result', 'Second result']);
      expect(report.attemptedConnectorIds, ['first', 'second']);
      expect(report.successfulConnectorIds, ['first', 'second']);
      expect(report.hasSourceSuccess, isTrue);
      expect(report.allSourcesFailed, isFalse);
      expect(report.warnings, isEmpty);
    });

    test('continues when a source throws and does not expose exception details', () async {
      final service = ResearchService(connectors: [
        _FakeConnector('broken', (query) async {
          throw StateError('secret token must not leak');
        }),
        _FakeConnector('healthy', (query) async => const [
          ResearchResult(
            title: 'Available result',
            url: 'https://example.com/available',
            sourceId: 'healthy',
          ),
        ]),
      ]);

      final report = await service.search(const ResearchQuery(text: 'opportunities'));

      expect(report.results.single.title, 'Available result');
      expect(report.attemptedConnectorIds, ['broken', 'healthy']);
      expect(report.successfulConnectorIds, ['healthy']);
      expect(report.warnings, hasLength(1));
      expect(report.warnings.single, contains('broken'));
      expect(report.warnings.join(' '), isNot(contains('secret token')));
    });

    test('reports when every configured source fails', () async {
      final service = ResearchService(connectors: [
        _FakeConnector('offline', (query) async => throw Exception('offline')),
      ]);

      final report = await service.search(const ResearchQuery(text: 'jobs'));

      expect(report.results, isEmpty);
      expect(report.hasSourceSuccess, isFalse);
      expect(report.allSourcesFailed, isTrue);
      expect(report.warnings, hasLength(1));
    });

    test('handles no configured sources as an empty search, not a failure', () async {
      final report = await ResearchService(connectors: const [])
          .search(const ResearchQuery(text: 'jobs'));

      expect(report.results, isEmpty);
      expect(report.attemptedConnectorIds, isEmpty);
      expect(report.allSourcesFailed, isFalse);
      expect(report.warnings, isEmpty);
    });

    test('rejects invalid query before calling any connector', () async {
      var called = false;
      final service = ResearchService(connectors: [
        _FakeConnector('source', (query) async {
          called = true;
          return const [];
        }),
      ]);

      await expectLater(
        service.search(const ResearchQuery(text: '  ')),
        throwsArgumentError,
      );
      expect(called, isFalse);
    });
  });
}
