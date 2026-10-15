import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auren/features/events/domain/auren_event.dart';
import 'package:auren/services/events/auren_events_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AurenEventsRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = AurenEventsRepository(firestore: firestore);
  });

  test('creates and streams public events', () async {
    final start = DateTime.now().add(const Duration(days: 2));
    final id = await repository.create(
      ownerId: 'host-1',
      title: 'Community meetup',
      description: 'Meet local builders',
      startsAt: start,
      endsAt: start.add(const Duration(hours: 2)),
      locationLabel: 'Community hall',
      capacity: 25,
    );

    final events = await repository.watchPublicEvents().first;
    expect(events, hasLength(1));
    expect(events.single.id, id);
    expect(events.single.title, 'Community meetup');
    expect(events.single.capacity, 25);
  });

  test('RSVP capacity decisions are idempotent per user', () async {
    final start = DateTime.now().add(const Duration(days: 2));
    final id = await repository.create(
      ownerId: 'host-1',
      title: 'Small meetup',
      description: '',
      startsAt: start,
      endsAt: start.add(const Duration(hours: 2)),
      capacity: 1,
    );

    expect(
      await repository.register(eventId: id, userId: 'user-1'),
      AurenEventRsvpStatus.going,
    );
    expect(
      await repository.register(eventId: id, userId: 'user-1'),
      AurenEventRsvpStatus.going,
    );
    expect(
      await repository.register(eventId: id, userId: 'user-2'),
      AurenEventRsvpStatus.waitlisted,
    );
    final event = (await firestore.collection('events').doc(id).get()).data()!;
    expect(event['confirmedCount'], 1);
  });

  test('cancelling a confirmed RSVP decrements the count exactly once', () async {
    final start = DateTime.now().add(const Duration(days: 2));
    final id = await repository.create(
      ownerId: 'host-1',
      title: 'Cancellation meetup',
      description: '',
      startsAt: start,
      endsAt: start.add(const Duration(hours: 2)),
      capacity: 2,
    );
    await repository.register(eventId: id, userId: 'user-1');

    expect(
      await repository.cancelRegistration(eventId: id, userId: 'user-1'),
      AurenEventRsvpStatus.cancelled,
    );
    expect(
      await repository.cancelRegistration(eventId: id, userId: 'user-1'),
      AurenEventRsvpStatus.cancelled,
    );
    final event = (await firestore.collection('events').doc(id).get()).data()!;
    expect(event['confirmedCount'], 0);
    expect(
      await repository.getRegistrationStatus(eventId: id, userId: 'user-1'),
      AurenEventRsvpStatus.cancelled,
    );
  });

  test('re-registering after cancellation restores a place when capacity is available', () async {
    final start = DateTime.now().add(const Duration(days: 2));
    final id = await repository.create(
      ownerId: 'host-1',
      title: 'Re-registration meetup',
      description: '',
      startsAt: start,
      endsAt: start.add(const Duration(hours: 2)),
      capacity: 1,
    );

    expect(
      await repository.register(eventId: id, userId: 'user-1'),
      AurenEventRsvpStatus.going,
    );
    await repository.cancelRegistration(eventId: id, userId: 'user-1');

    expect(
      await repository.register(eventId: id, userId: 'user-1'),
      AurenEventRsvpStatus.going,
    );
    final event = (await firestore.collection('events').doc(id).get()).data()!;
    expect(event['confirmedCount'], 1);
    expect(
      await repository.getRegistrationStatus(eventId: id, userId: 'user-1'),
      AurenEventRsvpStatus.going,
    );
  });

  test('re-registering after cancellation joins waitlist when capacity is full', () async {
    final start = DateTime.now().add(const Duration(days: 2));
    final id = await repository.create(
      ownerId: 'host-1',
      title: 'Re-registration waitlist',
      description: '',
      startsAt: start,
      endsAt: start.add(const Duration(hours: 2)),
      capacity: 1,
    );
    await repository.register(eventId: id, userId: 'user-1');
    await repository.cancelRegistration(eventId: id, userId: 'user-1');
    expect(
      await repository.register(eventId: id, userId: 'user-2'),
      AurenEventRsvpStatus.going,
    );

    expect(
      await repository.register(eventId: id, userId: 'user-1'),
      AurenEventRsvpStatus.waitlisted,
    );
    final event = (await firestore.collection('events').doc(id).get()).data()!;
    expect(event['confirmedCount'], 1);
  });

  test('cancelling a waitlisted RSVP does not change confirmed count', () async {
    final start = DateTime.now().add(const Duration(days: 2));
    final id = await repository.create(
      ownerId: 'host-1',
      title: 'Waitlist meetup',
      description: '',
      startsAt: start,
      endsAt: start.add(const Duration(hours: 2)),
      capacity: 1,
    );
    await repository.register(eventId: id, userId: 'user-1');
    await repository.register(eventId: id, userId: 'user-2');

    expect(
      await repository.cancelRegistration(eventId: id, userId: 'user-2'),
      AurenEventRsvpStatus.cancelled,
    );
    final event = (await firestore.collection('events').doc(id).get()).data()!;
    expect(event['confirmedCount'], 1);
  });

}
