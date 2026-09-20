class AurenPost {
  final String id, authorId, text, mediaUrl, mediaType;
  final DateTime createdAt;
  final int likes, comments;

  const AurenPost({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.mediaUrl = '',
    this.mediaType = 'none',
    this.likes = 0,
    this.comments = 0,
  });

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'text': text,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'likes': likes,
        'comments': comments,
      };

  factory AurenPost.fromMap(String id, Map<String, dynamic> m) => AurenPost(
        id: id,
        authorId: m['authorId']?.toString() ?? '',
        text: m['text']?.toString() ?? '',
        mediaUrl: m['mediaUrl']?.toString() ?? '',
        mediaType: m['mediaType']?.toString() ?? 'none',
        createdAt:
            DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
        likes: (m['likes'] as num?)?.toInt() ?? 0,
        comments: (m['comments'] as num?)?.toInt() ?? 0,
      );
}