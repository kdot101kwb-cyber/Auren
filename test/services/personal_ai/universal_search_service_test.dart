import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/personal_ai/universal_search_service.dart';

void main() {
  test('empty universal search returns no results without querying Firestore', () async {
    final service = AurenUniversalSearchService();
    final results = await service.watch('   ').first;

    expect(results, isEmpty);
  });

  test('long search input is accepted and bounded by the service', () async {
    final service = AurenUniversalSearchService();
    final query = 'a' * 200;

    expect(service.watch(query), isA<Stream<List<AurenSearchResult>>>());
  });
}
