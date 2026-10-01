class AurenEntertainmentItem {
  final String id, title, type, description, imageUrl, mediaUrl, mediaKind, creatorId, channelId, country, language, year, trailerUrl, artistName, albumName, source, sourceUrl, licenseNote, issn;
  final List<String> genres;
  final int seasons, episodes;
  const AurenEntertainmentItem({
    required this.id, required this.title, required this.type,
    required this.description, required this.imageUrl,
    required this.mediaUrl, required this.mediaKind,
    this.creatorId = '', this.channelId = '', this.country = '', this.language = '', this.year = '',
    this.genres = const [], this.seasons = 0, this.episodes = 0, this.trailerUrl = '', this.artistName = '', this.albumName = '', this.source = '', this.sourceUrl = '', this.licenseNote = '', this.issn = '',
  });

  bool get isVideo => mediaKind == 'video' || mediaUrl.toLowerCase().endsWith('.mp4') || mediaUrl.toLowerCase().contains('.m3u8');
  bool get isAudio => mediaKind == 'audio';
  bool get isCatalogOnly => mediaUrl.trim().isEmpty && source.isNotEmpty;
  bool get hasExternalSource => sourceUrl.trim().isNotEmpty && (sourceUrl.startsWith('https://') || sourceUrl.startsWith('http://'));
  bool get hasPlayableMedia => mediaUrl.trim().isNotEmpty && (isVideo || isAudio);

  factory AurenEntertainmentItem.fromMap(String id, Map<String, dynamic> d) => AurenEntertainmentItem(
    id: id,
    title: d['title'] ?? '',
    type: d['type'] ?? 'Global Series',
    description: d['description'] ?? '',
    imageUrl: d['imageUrl'] ?? '',
    mediaUrl: d['mediaUrl'] ?? d['videoUrl'] ?? d['audioUrl'] ?? '',
    mediaKind: d['mediaKind'] ?? (d['videoUrl'] != null ? 'video' : d['audioUrl'] != null ? 'audio' : ''),
    creatorId: (d['creatorId'] ?? d['ownerId'] ?? d['authorId'] ?? d['uid'] ?? '').toString(),
    channelId: (d['channelId'] ?? '').toString(),
    country: (d['country'] ?? '').toString(), language: (d['language'] ?? '').toString(), year: (d['year'] ?? '').toString(),
    trailerUrl: (d['trailerUrl'] ?? d['trailer'] ?? '').toString(),
    artistName: (d['artistName'] ?? d['artist'] ?? '').toString(),
    albumName: (d['albumName'] ?? d['album'] ?? '').toString(),
    source: (d['source'] ?? '').toString(), sourceUrl: (d['sourceUrl'] ?? '').toString(), licenseNote: (d['licenseNote'] ?? '').toString(), issn: (d['issn'] ?? '').toString(),
    genres: ((d['genres'] as List?)?.whereType<String>().take(10).toList() ?? const []),
    seasons: (d['seasons'] as num?)?.toInt() ?? 0, episodes: (d['episodes'] as num?)?.toInt() ?? 0,
  );
}