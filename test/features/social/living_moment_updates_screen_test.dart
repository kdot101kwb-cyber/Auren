import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/social/presentation/living_moment_updates_screen.dart';
import 'package:auren/services/social/moment_update_repository.dart';

void main() {
  group('AurenLivingMomentUpdatesScreen', () {
    late FakeFirebaseFirestore firestore;
    late MomentUpdateRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = MomentUpdateRepository(firestore: firestore);
    });

    Future<void> pumpScreen(
      WidgetTester tester, {
      required String ownerId,
      required String currentUid,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AurenLivingMomentUpdatesScreen(
            postId: 'moment_1',
            ownerId: ownerId,
            currentUid: currentUid,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('owner can start and add to a Living Moment', (tester) async {
      await pumpScreen(tester, ownerId: 'owner_1', currentUid: 'owner_1');

      expect(find.text('The story starts here'), findsOneWidget);
      expect(find.text('Add the first update'), findsOneWidget);
      expect(find.byTooltip('Add update'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('non-owner can read the timeline but cannot publish',
        (tester) async {
      await pumpScreen(tester, ownerId: 'owner_1', currentUid: 'viewer_1');

      expect(find.text('The story starts here'), findsOneWidget);
      expect(find.text('New updates from this moment will appear here.'),
          findsOneWidget);
      expect(find.byTooltip('Add update'), findsNothing);
      expect(find.text('Add the first update'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('renders stored updates with their author attribution',
        (tester) async {
      await firestore
          .collection('posts')
          .doc('moment_1')
          .collection('moment_updates')
          .doc('update_1')
          .set({
        'authorId': 'owner_1',
        'text': 'First milestone reached',
        'createdAt': DateTime.utc(2026, 10, 20),
      });

      await pumpScreen(tester, ownerId: 'owner_1', currentUid: 'viewer_1');

      expect(find.text('First milestone reached'), findsOneWidget);
      expect(find.text('Moment owner'), findsOneWidget);
    });
  });
}
