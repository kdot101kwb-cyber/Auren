import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/social/moment_update_repository.dart';

void main() {
  group('MomentUpdateRepository', () {
    late FakeFirebaseFirestore firestore;
    late MomentUpdateRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = MomentUpdateRepository(firestore: firestore);
    });

    test('persists trimmed updates under the parent post', () async {
      await repository.add(
        postId: 'post_1',
        authorId: 'owner_1',
        text: '  First milestone reached  ',
      );

      final snapshot = await firestore
          .collection('posts')
          .doc('post_1')
          .collection('moment_updates')
          .get();

      expect(snapshot.docs, hasLength(1));
      expect(snapshot.docs.single.data()['authorId'], 'owner_1');
      expect(snapshot.docs.single.data()['text'], 'First milestone reached');
    });

    test('rejects empty and overlong updates', () async {
      await expectLater(
        repository.add(postId: 'post_1', authorId: 'owner_1', text: '  '),
        throwsArgumentError,
      );
      await expectLater(
        repository.add(
          postId: 'post_1',
          authorId: 'owner_1',
          text: 'x' * 1201,
        ),
        throwsArgumentError,
      );
    });

    test('parses missing timestamps safely', () {
      final update = MomentUpdate.fromMap('update_1', {
        'authorId': 'owner_1',
        'text': 'A new milestone',
      });

      expect(update.id, 'update_1');
      expect(update.authorId, 'owner_1');
      expect(update.text, 'A new milestone');
      expect(update.createdAt, isNull);
    });
  });
}
