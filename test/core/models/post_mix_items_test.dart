import 'package:flutter_test/flutter_test.dart';
import 'package:auren/core/models/post.dart';

void main() {
  group('AurenPost mixed-media compatibility', () {
    test('round-trips a living mix with multiple attachment types', () {
      final post = AurenPost(
        id: 'mix_1',
        authorId: 'user_1',
        text: 'A moment in progress',
        contentType: 'mix',
        contextLabel: 'Living Moment',
        createdAt: DateTime.utc(2026, 10, 19),
        mixItems: const [
          {'type': 'image', 'url': 'https://example.com/photo.jpg'},
          {'type': 'audio', 'url': 'https://example.com/audio.mp3'},
          {'type': 'link', 'url': 'https://example.com/story'},
        ],
      );

      final restored = AurenPost.fromMap(post.id, post.toMap());

      expect(restored.contentType, 'mix');
      expect(restored.mixItems, hasLength(3));
      expect(restored.mixItems[0]['type'], 'image');
      expect(restored.mixItems[1]['type'], 'audio');
      expect(restored.mixItems[2]['url'], 'https://example.com/story');
    });

    test('reads legacy posts without mixed-media fields', () {
      final post = AurenPost.fromMap('legacy_1', {
        'authorId': 'user_2',
        'text': 'Old post',
        'mediaUrl': 'https://example.com/old.jpg',
        'mediaType': 'image',
        'contentType': 'moment',
        'createdAt': '2026-10-19T00:00:00.000Z',
      });

      expect(post.text, 'Old post');
      expect(post.mediaType, 'image');
      expect(post.mixItems, isEmpty);
      expect(post.toMap().containsKey('mixItems'), isFalse);
    });

    test('drops malformed attachment entries without a URL', () {
      final post = AurenPost.fromMap('mixed_2', {
        'authorId': 'user_3',
        'text': 'Mixed',
        'createdAt': '2026-10-19T00:00:00.000Z',
        'mixItems': [
          {'type': 'image', 'url': 'https://example.com/a.jpg'},
          {'type': 'video'},
          'not-an-attachment',
        ],
      });

      expect(post.mixItems, hasLength(1));
      expect(post.mixItems.single['url'], 'https://example.com/a.jpg');
    });
  });
}
