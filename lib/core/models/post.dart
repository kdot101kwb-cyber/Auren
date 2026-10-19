class AurenPost {
  final String id, authorId, text, mediaUrl, mediaType, contentType, contextLabel, actionLabel, communityId, postFormat, livingStatus, livingSummary;
  final List<Map<String, dynamic>> mixBlocks;
  final DateTime createdAt;
  final int likes, comments;

  const AurenPost({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.mediaUrl = '',
    this.mediaType = 'none',
    this.contentType = 'moment',
    this.contextLabel = '',
    this.actionLabel = '',
    this.communityId = '',
    this.likes = 0,
    this.comments = 0,
    this.postFormat = 'standard',
    this.mixBlocks = const [],
    this.livingStatus = 'active',
    this.livingSummary = '',
  });

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'text': text,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'contentType': contentType,
        'contextLabel': contextLabel,
        'actionLabel': actionLabel,
        'communityId': communityId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'likes': likes,
        'comments': comments,
        'postFormat': postFormat,
        'mixBlocks': mixBlocks,
        'livingStatus': livingStatus,
        'livingSummary': livingSummary,
      };

  factory AurenPost.fromMap(String id, Map<String, dynamic> m) => AurenPost(
        id: id,
        authorId: m['authorId']?.toString() ?? '',
        text: m['text']?.toString() ?? '',
        mediaUrl: m['mediaUrl']?.toString() ?? '',
        mediaType: m['mediaType']?.toString() ?? 'none',
        contentType: m['contentType']?.toString() ?? 'moment',
        contextLabel: m['contextLabel']?.toString() ?? '',
        actionLabel: m['actionLabel']?.toString() ?? '',
        communityId: m['communityId']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
        likes: (m['likes'] as num?)?.toInt() ?? 0,
        comments: (m['comments'] as num?)?.toInt() ?? 0,
        postFormat: m['postFormat']?.toString() ?? 'standard',
        mixBlocks: (m['mixBlocks'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((block) => Map<String, dynamic>.from(block))
            .toList(growable: false),
        livingStatus: m['livingStatus']?.toString() ?? 'active',
        livingSummary: m['livingSummary']?.toString() ?? '',
      );
}