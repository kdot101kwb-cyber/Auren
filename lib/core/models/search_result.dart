enum AurenSearchType { people, posts, businesses, places, opportunities, ai }

class AurenSearchResult {
  final String id;
  final AurenSearchType type;
  final String title;
  final String subtitle;
  final String? imageUrl;

  const AurenSearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.imageUrl,
  });
}
