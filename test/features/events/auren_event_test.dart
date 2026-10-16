import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/events/domain/auren_event.dart';

void main() {
  final startsAt = DateTime.utc(2026, 12, 1, 10);
  final endsAt = DateTime.utc(2026, 12, 1, 12);

  AurenEvent makeEvent({int? capacity}) => AurenEvent(
        id: 'event-1',
        hostId: 'host-1',
        title: 'Community meetup',
        startsAt: startsAt,
        endsAt: endsAt,
        capacity: capacity,
      );

  group('AurenEvent validation', () {
    test('accepts a valid event with no capacity limit', () {
      expect(makeEvent().capacity, isNull);
    });

    test('rejects blank identifiers and titles', () {
      expect(
        () => AurenEvent(
          id: ' ',
          hostId: 'host-1',
          title: 'Meetup',
          startsAt: startsAt,
          endsAt: endsAt,
        ),
        throwsArgumentError,
      );
      expect(
        () => AurenEvent(
          id: 'event-1',
          hostId: 'host-1',
          title: ' ',
          startsAt: startsAt,
          endsAt: endsAt,
        ),
        throwsArgumentError,
      );
    });

    test('rejects end times that are not after start times', () {
      expect(
        () => AurenEvent(
          id: 'event-1',
          hostId: 'host-1',
          title: 'Meetup',
          startsAt: startsAt,
          endsAt: startsAt,
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-positive capacity', () {
      expect(() => makeEvent(capacity: 0), throwsArgumentError);
      expect(() => makeEvent(capacity: -1), throwsArgumentError);
    });
  });

  group('AurenEventCapacityPolicy', () {
    test('confirms an attendee while capacity remains', () {
      expect(
        AurenEventCapacityPolicy.statusForNewRsvp(
          event: makeEvent(capacity: 10),
          confirmedAttendees: 9,
        ),
        AurenEventRsvpStatus.going,
      );
    });

    test('waitlists new RSVPs when capacity is reached', () {
      expect(
        AurenEventCapacityPolicy.statusForNewRsvp(
          event: makeEvent(capacity: 10),
          confirmedAttendees: 10,
        ),
        AurenEventRsvpStatus.waitlisted,
      );
    });

    test('treats null capacity as unlimited', () {
      expect(
        AurenEventCapacityPolicy.statusForNewRsvp(
          event: makeEvent(),
          confirmedAttendees: 100000,
        ),
        AurenEventRsvpStatus.going,
      );
    });

    test('rejects negative attendee counts', () {
      expect(
        () => AurenEventCapacityPolicy.statusForNewRsvp(
          event: makeEvent(capacity: 10),
          confirmedAttendees: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}
