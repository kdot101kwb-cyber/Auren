import 'package:firebase_core/firebase_core.dart';

import '../../core/models/search_result.dart' as core;
import '../search/global_search_repository.dart';
import '../search/search_repository.dart';

/// Compatibility result model for callers of Personal AI search.
/// The canonical Global Search repository owns discovery and safety filtering.
enum AurenSearchType {
  business,
  product,
  post,
  person,
  entertainment,
  place,
  opportunity,
}

class AurenSearchResult {
  final String id;
  final String title;
  final String subtitle;
  final AurenSearchType type;
  final String? imageUrl;

  const AurenSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.imageUrl,
  });
}

class AurenUniversalSearchService {
  final AurenSearchRepository? _repository;

  AurenUniversalSearchService({AurenSearchRepository? repository})
      : _repository = repository;

  Stream<List<AurenSearchResult>> watch(String query, {String? uid}) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return Stream.value(const <AurenSearchResult>[]);
    }
    if (_repository == null && Firebase.apps.isEmpty) {
      return Stream.value(const <AurenSearchResult>[]);
    }

    final boundedQuery = normalized.length > 80
        ? normalized.substring(0, 80)
        : normalized;
    final repository = _repository ?? AurenGlobalSearchRepository();

    return Stream.fromFuture(repository.search(boundedQuery, uid: uid)).map(
      (results) => results
          .map(_adapt)
          .whereType<AurenSearchResult>()
          .take(60)
          .toList(growable: false),
    );
  }

  AurenSearchResult? _adapt(core.AurenSearchResult result) {
    final type = switch (result.type) {
      core.AurenSearchType.businesses => AurenSearchType.business,
      core.AurenSearchType.products => AurenSearchType.product,
      core.AurenSearchType.posts => AurenSearchType.post,
      core.AurenSearchType.people => AurenSearchType.person,
      core.AurenSearchType.entertainment => AurenSearchType.entertainment,
      core.AurenSearchType.places => AurenSearchType.place,
      core.AurenSearchType.opportunities => AurenSearchType.opportunity,
      core.AurenSearchType.ai => null,
    };
    if (type == null) return null;
    return AurenSearchResult(
      id: result.id,
      title: result.title,
      subtitle: result.subtitle,
      type: type,
      imageUrl: result.imageUrl,
    );
  }
}
