import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/creator/creator_studio_repository.dart';

void main() {
  test('creator stats model exposes total content', () {
    const stats = AurenCreatorStats(posts: 4, likes: 12, mediaPosts: 3);
    expect(stats.totalContent, 4);
  });

  test('publishing a Short creates public feed data and a creator channel', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = AurenCreatorStudioRepository(firestore: firestore);
    final postId = await repository.publish(
      uid: 'creator-123456',
      text: 'Funny animated clip',
      mediaUrl: 'https://example.com/short.mp4',
      mediaType: 'video',
      contentType: 'short',
      category: 'كرتون',
      tags: ['animation', 'ضحك', 'animation'],
    );

    final post = (await firestore.collection('posts').doc(postId).get()).data();
    expect(post?['contentType'], 'short');
    expect(post?['mediaType'], 'video');

    final shorts = await firestore.collection('entertainment_items').get();
    expect(shorts.docs, hasLength(1));
    final short = shorts.docs.single.data();
    expect(short['type'], 'Short');
    expect(short['mediaKind'], 'video');
    expect(short['visibility'], 'public');
    expect(short['creatorId'], 'creator-123456');
    expect(short['category'], 'كرتون');
    expect(short['tags'], ['animation', 'ضحك']);
    expect(short['channelId'], isNotEmpty);

    final channels = await firestore.collection('content_channels').get();
    expect(channels.docs, hasLength(1));
    expect(channels.docs.single.id, short['channelId']);
    expect(channels.docs.single.data()['ownerId'], 'creator-123456');
  });

  test('publishing a Short rejects a missing video URL', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = AurenCreatorStudioRepository(firestore: firestore);
    await expectLater(
      repository.publish(
        uid: 'creator-123456',
        text: 'Missing video',
        mediaType: 'video',
        contentType: 'short',
      ),
      throwsArgumentError,
    );
    expect((await firestore.collection('entertainment_items').get()).docs, isEmpty);
  });
}
