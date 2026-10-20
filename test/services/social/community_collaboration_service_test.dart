import 'package:auren/services/social/community_collaboration_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late AurenCollaborationService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'member-a'),
    );
    service = AurenCollaborationService(db: firestore, auth: auth);
  });

  test('signed-out service exposes no current UID and guards required UID', () {
    final signedOutService = AurenCollaborationService(
      db: firestore,
      auth: MockFirebaseAuth(signedIn: false),
    );

    expect(signedOutService.isSignedIn, isFalse);
    expect(signedOutService.currentUid, isNull);
    expect(() => signedOutService.uid, throwsStateError);
  });

  test('club creation trims fields and starts with owner membership', () async {
    final id = await service.createClub(
      name: '  Readers  ',
      description: ' Monthly reading group ',
      category: ' Books ',
    );

    final snapshot =
        await firestore.collection('community_clubs').doc(id).get();
    expect(snapshot.data()?['name'], 'Readers');
    expect(snapshot.data()?['description'], 'Monthly reading group');
    expect(snapshot.data()?['category'], 'Books');
    expect(snapshot.data()?['ownerId'], 'member-a');
    expect(snapshot.data()?['memberIds'], ['member-a']);
    expect(snapshot.data()?['memberCount'], 1);
  });

  test('club creation rejects blank and oversized names', () async {
    await expectLater(
      service.createClub(name: ' ', description: '', category: 'Books'),
      throwsArgumentError,
    );
    await expectLater(
      service.createClub(
        name: List.filled(81, 'x').join(),
        description: '',
        category: 'Books',
      ),
      throwsArgumentError,
    );
  });

  test('club membership is idempotent and members can leave', () async {
    final clubId = await service.createClub(
      name: 'Chess',
      description: '',
      category: 'Games',
    );
    final otherMemberService = AurenCollaborationService(
      db: firestore,
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'member-b'),
      ),
    );

    await otherMemberService.joinClub(clubId);
    await otherMemberService.joinClub(clubId);
    var snapshot =
        await firestore.collection('community_clubs').doc(clubId).get();
    expect(snapshot.data()?['memberIds'], ['member-a', 'member-b']);
    expect(snapshot.data()?['memberCount'], 2);

    await otherMemberService.leaveClub(clubId);
    snapshot = await firestore.collection('community_clubs').doc(clubId).get();
    expect(snapshot.data()?['memberIds'], ['member-a']);
    expect(snapshot.data()?['memberCount'], 1);
  });

  test('cause volunteer registration is idempotent', () async {
    final causeId = await service.createCause(
      title: 'Tree planting',
      description: 'Plant trees together.',
      category: 'Environment',
    );
    final otherMemberService = AurenCollaborationService(
      db: firestore,
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'member-b'),
      ),
    );

    await otherMemberService.volunteerForCause(causeId);
    await otherMemberService.volunteerForCause(causeId);
    final snapshot =
        await firestore.collection('volunteer_causes').doc(causeId).get();
    expect(snapshot.data()?['volunteerIds'], ['member-a', 'member-b']);
  });

  test('space creation starts with a single owner member', () async {
    final id = await service.createSpace(
      title: 'Community garden',
      description: 'Plan a shared garden project.',
    );

    final snapshot =
        await firestore.collection('collaboration_spaces').doc(id).get();
    expect(snapshot.data()?['ownerId'], 'member-a');
    expect(snapshot.data()?['title'], 'Community garden');
    expect(snapshot.data()?['memberIds'], ['member-a']);
  });

  test('cause creation opens a volunteer opportunity owned by creator',
      () async {
    final id = await service.createCause(
      title: 'Park cleanup',
      description: 'Help clean the local park.',
      category: 'Environment',
    );

    final snapshot =
        await firestore.collection('volunteer_causes').doc(id).get();
    expect(snapshot.data()?['ownerId'], 'member-a');
    expect(snapshot.data()?['status'], 'open');
    expect(snapshot.data()?['volunteerIds'], ['member-a']);
  });

  test('club owner cannot leave their own club', () async {
    final clubId = await service.createClub(
      name: 'Owner club',
      description: '',
      category: 'Community',
    );

    await expectLater(service.leaveClub(clubId), throwsStateError);
    final snapshot =
        await firestore.collection('community_clubs').doc(clubId).get();
    expect(snapshot.data()?['memberIds'], ['member-a']);
    expect(snapshot.data()?['memberCount'], 1);
  });

  test('space invitations normalize member identifiers', () async {
    final spaceId = await service.createSpace(
      title: 'Design team',
      description: 'Review designs together',
    );

    await service.inviteToSpace(
      spaceId: spaceId,
      memberUid: ' member-b ',
    );
    final snapshot =
        await firestore.collection('collaboration_spaces').doc(spaceId).get();
    expect(snapshot.data()?['memberIds'], ['member-a', 'member-b']);
  });

  test('only the collaboration space owner can invite members', () async {
    final spaceId = await service.createSpace(
      title: 'Planning team',
      description: 'Shared work',
    );
    final nonOwnerService = AurenCollaborationService(
      db: firestore,
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'member-b'),
      ),
    );

    await expectLater(
      nonOwnerService.inviteToSpace(
        spaceId: spaceId,
        memberUid: 'member-c',
      ),
      throwsStateError,
    );
    final snapshot =
        await firestore.collection('collaboration_spaces').doc(spaceId).get();
    expect(snapshot.data()?['memberIds'], ['member-a']);
  });

  test('cause creation rejects empty descriptions and categories', () async {
    await expectLater(
      service.createCause(
        title: 'Cleanup',
        description: ' ',
        category: 'Environment',
      ),
      throwsArgumentError,
    );
    await expectLater(
      service.createCause(
        title: 'Cleanup',
        description: 'Help clean the park.',
        category: ' ',
      ),
      throwsArgumentError,
    );
  });

  test('reports reuse existing reports collection schema', () async {
    final id = await service.reportCommunityContent(
      reportedUid: 'member-b',
      reason: 'Harassment in a community post',
      contentId: 'post-1',
      contentType: 'community_post',
    );

    final snapshot = await firestore.collection('reports').doc(id).get();
    expect(snapshot.data()?['reporterUid'], 'member-a');
    expect(snapshot.data()?['reportedUid'], 'member-b');
    expect(snapshot.data()?['status'], 'open');
    expect(snapshot.data()?['contentId'], 'post-1');
  });

  test('reporting self or an empty reason is rejected', () async {
    await expectLater(
      service.reportCommunityContent(
        reportedUid: 'member-a',
        reason: 'Invalid target',
      ),
      throwsArgumentError,
    );
    await expectLater(
      service.reportCommunityContent(
        reportedUid: 'member-b',
        reason: ' ',
      ),
      throwsArgumentError,
    );
  });
}
