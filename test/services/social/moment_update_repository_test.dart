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
    test('watch returns updates ordered newest first and capped at 50', () async {
      final updates = firestore.collection('posts').doc('post_feed')
          .collection('moment_updates');
      for (var i = 0; i < 55; i++) {
        await updates.doc('update_$i').set({
          'authorId': 'owner_1',
          'text': 'Update $i',
          'createdAt': DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
        });
      }

      final result = await repository.watch('post_feed').first;

      expect(result, hasLength(50));
      expect(result.first.text, 'Update 54');
      expect(result.last.text, 'Update 5');
    });

    test('delete removes only the requested update document', () async {
      final updates = firestore.collection('posts').doc('post_delete')
          .collection('moment_updates');
      await updates.doc('keep').set({'authorId': 'owner_1', 'text': 'Keep'});
      await updates.doc('remove').set({'authorId': 'owner_1', 'text': 'Remove'});

      await repository.delete(postId: 'post_delete', updateId: 'remove');

      expect((await updates.doc('remove').get()).exists, isFalse);
      expect((await updates.doc('keep').get()).exists, isTrue);
    });

  });
}

    test('watch returns updates ordered newest first and capped at 50', () async {
      final post = firestore.collection('posts').doc('post_feed');
      final updates = post.collection('moment_updates');
      for (var i = 0; i < 55; i++) {
        await updates.doc('update_$i').set({
          'authorId': 'owner_1',
          'text': 'Update $i',
          'createdAt': DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
        });
      }

      final result = await repository.watch('post_feed').first;

      expect(result, hasLength(50));
      expect(result.first.text, 'Update 54');
      expect(result.last.text, 'Update 5');
    });

    test('delete removes only the requested update document', () async {
      final updates = firestore.collection('posts').doc('post_delete')
          .collection('moment_updates');
      await updates.doc('keep').set({'authorId': 'owner_1', 'text': 'Keep'});
      await updates.doc('remove').set({'authorId': 'owner_1', 'text': 'Remove'});

      await repository.delete(postId: 'post_delete', updateId: 'remove');

      expect((await updates.doc('remove').get()).exists, isFalse);
      expect((await updates.doc('keep').get()).exists, isTrue);
    });
