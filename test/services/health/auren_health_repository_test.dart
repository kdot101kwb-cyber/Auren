import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/health/auren_health_repository.dart';
import 'package:auren/services/health/health_data_sharing_consent.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AurenHealthRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = AurenHealthRepository(firestore: firestore);
  });

  HealthDataSharingConsent consentAt(DateTime time) =>
      HealthDataSharingConsent.fromUserConfirmation(
        accepted: true,
        purpose: 'User requested health check-in sync',
        grantedAt: time,
      );

  test('remote reads fail without explicit health sharing consent', () async {
    await expectLater(
      repository.watchCheckins('user-1').first,
      throwsA(isA<StateError>()),
    );
    final snapshot = await firestore
        .collection('users')
        .doc('user-1')
        .collection('healthCheckins')
        .get();
    expect(snapshot.docs, isEmpty);
  });

  test('remote writes fail before touching Firestore without consent', () async {
    await expectLater(
      repository.saveCheckin(
        uid: 'user-1',
        dateId: '2026-10-21',
        activityMinutes: 20,
        waterGlasses: 4,
        sleepHours: 7,
        mood: 4,
      ),
      throwsA(isA<StateError>()),
    );
    final snapshot = await firestore
        .collection('users')
        .doc('user-1')
        .collection('healthCheckins')
        .get();
    expect(snapshot.docs, isEmpty);
  });

  test('consent cannot be created when the user has not accepted', () {
    expect(
      () => HealthDataSharingConsent.fromUserConfirmation(
        accepted: false,
        purpose: 'Sync health check-ins',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('consent requires a bounded, non-empty purpose', () {
    expect(
      () => HealthDataSharingConsent.fromUserConfirmation(
        accepted: true,
        purpose: '   ',
      ),
      throwsArgumentError,
    );
    expect(
      () => HealthDataSharingConsent.fromUserConfirmation(
        accepted: true,
        purpose: 'x' * 161,
      ),
      throwsArgumentError,
    );
  });

  test('expired consent is rejected before remote writes', () async {
    final consent = consentAt(
      DateTime.now().toUtc().subtract(
        HealthDataSharingConsent.maxAge + const Duration(seconds: 1),
      ),
    );

    await expectLater(
      repository.saveCheckin(
        uid: 'user-1',
        dateId: '2026-10-21',
        activityMinutes: 20,
        waterGlasses: 4,
        sleepHours: 7,
        mood: 4,
        consent: consent,
      ),
      throwsA(isA<StateError>()),
    );

    final snapshot = await firestore
        .collection('users')
        .doc('user-1')
        .collection('healthCheckins')
        .get();
    expect(snapshot.docs, isEmpty);
  });

  test('confirmed consent enables bounded remote check-in reads and writes',
      () async {
    final consent = consentAt(DateTime.now().toUtc());

    await repository.saveCheckin(
      uid: 'user-1',
      dateId: '2026-10-22',
      activityMinutes: 20,
      waterGlasses: 4,
      sleepHours: 7,
      mood: 4,
      consent: consent,
    );

    final records = await repository.watchCheckins(
      'user-1',
      consent: consent,
    ).first;
    expect(records, hasLength(1));
    expect(records.single.activityMinutes, 20);
    expect(records.single.waterGlasses, 4);
    expect(records.single.sleepHours, 7);
    expect(records.single.mood, 4);
  });

  test('rejects invalid check-in values even after consent', () async {
    final consent = consentAt(DateTime.now().toUtc());
    await expectLater(
      repository.saveCheckin(
        uid: 'user-1',
        dateId: '2026-10-22',
        activityMinutes: 1441,
        waterGlasses: 4,
        sleepHours: 7,
        mood: 4,
        consent: consent,
      ),
      throwsArgumentError,
    );
  });
}
