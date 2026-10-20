import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/social/post_repository.dart';

void main() {
  group('PostRepository.updateContent media type', () {
    late FakeFirebaseFirestore firestore;
    late PostRepository repository;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      repository = PostRepository(firestore: firestore);
      await firestore.collection('posts').doc('post-1').set({
        'text': 'Old post',
        'mediaUrl': 'https://example.com/old.jpg',
        'mediaType': 'image',
      });
    });

    test('preserves the selected video type', () async {
      await repository.updateContent(
        'post-1',
        text: 'Video post',
        mediaUrl: 'https://example.com/clip.mp4',
        mediaType: 'video',
      );

      final post = (await firestore.collection('posts').doc('post-1').get()).data()!;
      expect(post['mediaUrl'], 'https://example.com/clip.mp4');
      expect(post['mediaType'], 'video');
      expect(post['text'], 'Video post');
    });

    test('preserves the selected audio type', () async {
      await repository.updateContent(
        'post-1',
        text: 'Audio post',
        mediaUrl: 'https://example.com/voice.mp3',
        mediaType: 'audio',
      );

      final post = (await firestore.collection('posts').doc('post-1').get()).data()!;
      expect(post['mediaType'], 'audio');
    });

    test('clears media type when media URL is removed', () async {
      await repository.updateContent(
        'post-1',
        text: 'Text only',
        mediaUrl: '',
        mediaType: 'video',
      );

      final post = (await firestore.collection('posts').doc('post-1').get()).data()!;
      expect(post['mediaUrl'], '');
      expect(post['mediaType'], 'none');
    });

    test('defaults to image for callers that omit media type', () async {
      await repository.updateContent(
        'post-1',
        text: 'Image post',
        mediaUrl: 'https://example.com/new.jpg',
      );

      final post = (await firestore.collection('posts').doc('post-1').get()).data()!;
      expect(post['mediaType'], 'image');
    });
  });
}
