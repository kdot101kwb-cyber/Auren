import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/social/utils/post_media_type.dart';

void main() {
  group('postMediaTypeFromUrl', () {
    test('returns none for an empty URL', () {
      expect(postMediaTypeFromUrl('  '), 'none');
    });

    test('detects common video extensions', () {
      expect(postMediaTypeFromUrl('https://cdn.example/video.mp4'), 'video');
      expect(postMediaTypeFromUrl('https://cdn.example/clip.MOV'), 'video');
      expect(postMediaTypeFromUrl('https://cdn.example/watch.webm?token=abc'), 'video');
      expect(postMediaTypeFromUrl('https://cdn.example/clip.mkv'), 'video');
    });

    test('treats other non-empty media URLs as images', () {
      expect(postMediaTypeFromUrl('https://cdn.example/photo.jpg'), 'image');
      expect(postMediaTypeFromUrl('https://cdn.example/media/123'), 'image');
    });
  });
}
