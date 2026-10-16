/// Pure domain primitives for AUREN Events & Experiences.
///
/// This batch intentionally contains no Firestore writes, ticket sales, payments,
/// or external notifications. Those require separate reviewed integration work.
enum AurenEventVisibility { public, followers, inviteOnly }

enum AurenEventRsvpStatus { going, interested, waitlisted, cancelled }

class AurenEvent {
  AurenEvent({
    required this.id,
    required this.hostId,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    this.description = '',
    this.locationLabel,
    this.capacity,
    this.visibility = AurenEventVisibility.public,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (hostId.trim().isEmpty) {
      throw ArgumentError.value(hostId, 'hostId', 'must not be empty');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
    if (!endsAt.isAfter(startsAt)) {
      throw ArgumentError('endsAt must be after startsAt');
    }
    if (capacity != null && capacity! <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be greater than zero');
    }
    if (locationLabel != null && locationLabel!.trim().isEmpty) {
      throw ArgumentError.value(locationLabel, 'locationLabel', 'must be null or non-empty');
    }
  }

  final String id;
  final String hostId;
  final String title;
  final String description;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? locationLabel;

  /// Null means the event host has not set a capacity limit.
  final int? capacity;
  final AurenEventVisibility visibility;

  bool get hasStarted => !DateTime.now().isBefore(startsAt);

  bool get isFinished => !DateTime.now().isBefore(endsAt);

  bool get isUpcoming => DateTime.now().isBefore(startsAt);
}

class AurenEventRsvp {
  AurenEventRsvp({
    required this.eventId,
    required this.userId,
    required this.status,
    required this.updatedAt,
  }) {
    if (eventId.trim().isEmpty) {
      throw ArgumentError.value(eventId, 'eventId', 'must not be empty');
    }
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'must not be empty');
    }
  }

  final String eventId;
  final String userId;
  final AurenEventRsvpStatus status;
  final DateTime updatedAt;
}

class AurenEventCapacityPolicy {
  const AurenEventCapacityPolicy._();

  /// Returns the status for a new RSVP using the current number of confirmed
  /// attendees. Callers must enforce one RSVP per user and serialize concurrent
  /// capacity updates in the persistence layer.
  static AurenEventRsvpStatus statusForNewRsvp({
    required AurenEvent event,
    required int confirmedAttendees,
  }) {
    if (confirmedAttendees < 0) {
      throw ArgumentError.value(
        confirmedAttendees,
        'confirmedAttendees',
        'must not be negative',
      );
    }

    final capacity = event.capacity;
    if (capacity == null || confirmedAttendees < capacity) {
      return AurenEventRsvpStatus.going;
    }
    return AurenEventRsvpStatus.waitlisted;
  }
}
