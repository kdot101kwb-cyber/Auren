import '../../core/models/search_result.dart';

/// Shared contract for AUREN's canonical, authorization-aware search catalog.
abstract interface class AurenSearchRepository {
  Future<List<AurenSearchResult>> search(String text, {String? uid});
}
