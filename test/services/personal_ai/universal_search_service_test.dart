import 'package:flutter_test/flutter_test.dart';
import 'package:auren/core/models/search_result.dart' as core;
import 'package:auren/services/personal_ai/universal_search_service.dart';
import 'package:auren/services/search/search_repository.dart';

class _FakeSearchRepository implements AurenSearchRepository {
  List<core.AurenSearchResult> results = [];
  String? lastQuery;
  String? lastUid;
  int calls = 0;

  @override
  Future<List<core.AurenSearchResult>> search(String text, {String? uid}) async {
    calls++;
    lastQuery = text;
    lastUid = uid;
    return results;
  }
}

core.AurenSearchResult _result(
  String id,
  core.AurenSearchType type,
) =>
    core.AurenSearchResult(
      id: id,
      type: type,
      title: 'Title $id',
      subtitle: 'Subtitle $id',
      imageUrl: 'https://example.test/$id.png',
    );

void main() {
  test('empty universal search returns no results without querying repository', () async {
    final repository = _FakeSearchRepository();
    final service = AurenUniversalSearchService(repository: repository);
    final results = await service.watch('   ', uid: 'viewer').first;

    expect(results, isEmpty);
    expect(repository.calls, 0);
  });

  test('search input is bounded and viewer identity is forwarded for safety filtering', () async {
    final repository = _FakeSearchRepository();
    final service = AurenUniversalSearchService(repository: repository);
    final query = 'a' * 200;

    expect(service.watch(query, uid: 'viewer'), isA<Stream<List<AurenSearchResult>>>());
    await service.watch(query, uid: 'viewer').first;

    expect(repository.lastQuery, 'a' * 80);
    expect(repository.lastUid, 'viewer');
    expect(repository.calls, 1);
  });

  test('legacy Personal AI search adapts all canonical domains consistently', () async {
    final repository = _FakeSearchRepository()
      ..results = [
        _result('person', core.AurenSearchType.people),
        _result('post', core.AurenSearchType.posts),
        _result('business', core.AurenSearchType.businesses),
        _result('product', core.AurenSearchType.products),
        _result('entertainment', core.AurenSearchType.entertainment),
        _result('place', core.AurenSearchType.places),
        _result('opportunity', core.AurenSearchType.opportunities),
        _result('ai', core.AurenSearchType.ai),
      ];
    final service = AurenUniversalSearchService(repository: repository);

    final results = await service.watch('auren').first;

    expect(results.map((result) => result.type).toList(), [
      AurenSearchType.person,
      AurenSearchType.post,
      AurenSearchType.business,
      AurenSearchType.product,
      AurenSearchType.entertainment,
      AurenSearchType.place,
      AurenSearchType.opportunity,
    ]);
    expect(results.any((result) => result.id == 'ai'), isFalse);
    expect(results.first.imageUrl, 'https://example.test/person.png');
  });

  test('universal search caps output to sixty adapted results', () async {
    final repository = _FakeSearchRepository()
      ..results = List.generate(
        75,
        (index) => _result('item-$index', core.AurenSearchType.posts),
      );
    final service = AurenUniversalSearchService(repository: repository);

    final results = await service.watch('many').first;

    expect(results, hasLength(60));
  });
}
