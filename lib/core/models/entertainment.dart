class AurenEntertainmentItem {
  final String id, title, type, description, imageUrl, mediaUrl, mediaKind;
  const AurenEntertainmentItem({
    required this.id, required this.title, required this.type,
    required this.description, required this.imageUrl,
    required this.mediaUrl, required this.mediaKind,
  });

  bool get isVideo => mediaKind == 'video' || mediaUrl.toLowerCase().endsWith('.mp4') || mediaUrl.toLowerCase().contains('.m3u8');
  bool get isAudio => mediaKind == 'audio';

  factory AurenEntertainmentItem.fromMap(String id, Map<String, dynamic> d) => AurenEntertainmentItem(
    id: id,
    title: d['title'] ?? '',
    type: d['type'] ?? 'Global Series',
    description: d['description'] ?? '',
    imageUrl: d['imageUrl'] ?? '',
    mediaUrl: d['mediaUrl'] ?? d['videoUrl'] ?? d['audioUrl'] ?? '',
    mediaKind: d['mediaKind'] ?? (d['videoUrl'] != null ? 'video' : d['audioUrl'] != null ? 'audio' : ''),
  );
}