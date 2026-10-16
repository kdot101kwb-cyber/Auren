import 'auren_news_article.dart';

/// Presentation ordering only; this policy does not assess truth or credibility.
class AurenNewsFeedPolicy {
  const AurenNewsFeedPolicy();

  /// Returns a new list ordered by breaking status, freshness, then recency.
  ///
  /// Input is not mutated. Future-dated items are treated as not fresh by the
  /// article's freshness check and remain ordered by publication time.
  List<AurenNewsArticle> sortForDisplay(
    Iterable<AurenNewsArticle> articles, {
    required DateTime now,
    Duration freshnessWindow = const Duration(hours: 48),
  }) {
    final result = List<AurenNewsArticle>.of(articles);
    result.sort((a, b) {
      final breakingOrder = _descendingBool(a.isBreaking, b.isBreaking);
      if (breakingOrder != 0) return breakingOrder;

      final freshA = a.isFreshAt(now, maxAge: freshnessWindow);
      final freshB = b.isFreshAt(now, maxAge: freshnessWindow);
      final freshnessOrder = _descendingBool(freshA, freshB);
      if (freshnessOrder != 0) return freshnessOrder;

      final publishedOrder = b.publishedAt.compareTo(a.publishedAt);
      if (publishedOrder != 0) return publishedOrder;
      return a.id.compareTo(b.id);
    });
    return result;
  }

  int _descendingBool(bool a, bool b) {
    if (a == b) return 0;
    return a ? -1 : 1;
  }
}
