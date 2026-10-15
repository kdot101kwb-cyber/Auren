import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/events/domain/auren_event.dart';

class AurenEventsRepository {
  AurenEventsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _events => _db.collection('events');

  Stream<List<AurenEvent>> watchPublicEvents() => _events
      .where('visibility', isEqualTo: 'public').limit(100).snapshots().map((snapshot) {
        final items = snapshot.docs.map((doc) => _fromMap(doc.id, doc.data())).toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        return items;
      });

  Future<String> create({
    required String ownerId, required String title, required String description,
    required DateTime startsAt, required DateTime endsAt,
    String? locationLabel, int? capacity,
  }) async {
    if (ownerId.trim().isEmpty) throw ArgumentError('يجب تسجيل الدخول أولاً.');
    final event = AurenEvent(
      id: 'pending', hostId: ownerId, title: title.trim(),
      description: description.trim(), startsAt: startsAt, endsAt: endsAt,
      locationLabel: (locationLabel?.trim().isEmpty ?? true) ? null : locationLabel!.trim(),
      capacity: capacity,
    );
    final ref = _events.doc();
    await ref.set({
      'ownerId': ownerId, 'title': event.title, 'description': event.description,
      'locationLabel': event.locationLabel, 'startsAt': Timestamp.fromDate(event.startsAt),
      'endsAt': Timestamp.fromDate(event.endsAt), 'capacity': event.capacity,
      'confirmedCount': 0, 'visibility': 'public',
      'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<AurenEventRsvpStatus> register({required String eventId, required String userId}) async {
    if (eventId.trim().isEmpty || userId.trim().isEmpty) {
      throw ArgumentError('معرّف الفعالية والمستخدم مطلوبان.');
    }
    final eventRef = _events.doc(eventId);
    final attendeeRef = eventRef.collection('attendees').doc(userId);
    return _db.runTransaction<AurenEventRsvpStatus>((transaction) async {
      final eventSnapshot = await transaction.get(eventRef);
      if (!eventSnapshot.exists || eventSnapshot.data() == null) throw StateError('الفعالية غير موجودة.');
      final attendeeSnapshot = await transaction.get(attendeeRef);
      if (attendeeSnapshot.exists) return _statusFromString(attendeeSnapshot.data()?['status'] as String?);
      final data = eventSnapshot.data()!;
      final event = _fromMap(eventSnapshot.id, data);
      if (!DateTime.now().isBefore(event.startsAt)) throw StateError('انتهى التسجيل لأن الفعالية بدأت.');
      final confirmed = (data['confirmedCount'] as num?)?.toInt() ?? 0;
      final status = AurenEventCapacityPolicy.statusForNewRsvp(event: event, confirmedAttendees: confirmed);
      if (status == AurenEventRsvpStatus.going) {
        transaction.update(eventRef, {'confirmedCount': confirmed + 1, 'updatedAt': FieldValue.serverTimestamp()});
      }
      transaction.set(attendeeRef, {
        'userId': userId, 'status': _statusToString(status),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return status;
    });
  }

  /// Returns the current user's RSVP status, or null when they have not registered.
  Future<AurenEventRsvpStatus?> getRegistrationStatus({
    required String eventId,
    required String userId,
  }) async {
    if (eventId.trim().isEmpty || userId.trim().isEmpty) {
      throw ArgumentError('معرّف الفعالية والمستخدم مطلوبان.');
    }
    final snapshot = await _events
        .doc(eventId)
        .collection('attendees')
        .doc(userId)
        .get();
    if (!snapshot.exists) return null;
    return _statusFromString(snapshot.data()?['status'] as String?);
  }

  /// Cancels the current RSVP and decrements the confirmed count atomically
  /// when the attendee previously held a confirmed place.
  Future<AurenEventRsvpStatus> cancelRegistration({
    required String eventId,
    required String userId,
  }) async {
    if (eventId.trim().isEmpty || userId.trim().isEmpty) {
      throw ArgumentError('معرّف الفعالية والمستخدم مطلوبان.');
    }
    final eventRef = _events.doc(eventId);
    final attendeeRef = eventRef.collection('attendees').doc(userId);
    return _db.runTransaction<AurenEventRsvpStatus>((transaction) async {
      final eventSnapshot = await transaction.get(eventRef);
      if (!eventSnapshot.exists || eventSnapshot.data() == null) {
        throw StateError('الفعالية غير موجودة.');
      }
      final attendeeSnapshot = await transaction.get(attendeeRef);
      if (!attendeeSnapshot.exists || attendeeSnapshot.data() == null) {
        throw StateError('لا يوجد تسجيل لإلغائه.');
      }
      final attendee = attendeeSnapshot.data()!;
      final currentStatus = _statusFromString(attendee['status'] as String?);
      if (currentStatus == AurenEventRsvpStatus.cancelled) return currentStatus;
      if (currentStatus != AurenEventRsvpStatus.going &&
          currentStatus != AurenEventRsvpStatus.waitlisted) {
        throw StateError('حالة التسجيل الحالية لا تسمح بالإلغاء.');
      }
      final event = _fromMap(eventSnapshot.id, eventSnapshot.data()!);
      if (!DateTime.now().isBefore(event.startsAt)) {
        throw StateError('لا يمكن إلغاء التسجيل بعد بدء الفعالية.');
      }
      if (currentStatus == AurenEventRsvpStatus.going) {
        final count =
            (eventSnapshot.data()!['confirmedCount'] as num?)?.toInt() ?? 0;
        if (count <= 0) {
          throw StateError('عدد المشاركين المؤكدين غير متسق؛ تعذر الإلغاء.');
        }
        transaction.update(eventRef, {
          'confirmedCount': count - 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.update(attendeeRef, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return AurenEventRsvpStatus.cancelled;
    });
  }

  AurenEvent _fromMap(String id, Map<String, dynamic> data) {
    final start = data['startsAt']; final end = data['endsAt'];
    if (start is! Timestamp || end is! Timestamp) throw const FormatException('Invalid event timestamps.');
    final rawCapacity = data['capacity'];
    final rawVisibility = data['visibility'];
    return AurenEvent(
      id: id, hostId: data['ownerId']?.toString() ?? '',
      title: data['title']?.toString() ?? '', description: data['description']?.toString() ?? '',
      locationLabel: data['locationLabel']?.toString(), startsAt: start.toDate(), endsAt: end.toDate(),
      capacity: rawCapacity is num ? rawCapacity.toInt() : null,
      visibility: rawVisibility == 'inviteOnly' ? AurenEventVisibility.inviteOnly
          : rawVisibility == 'followers' ? AurenEventVisibility.followers : AurenEventVisibility.public,
    );
  }

  String _statusToString(AurenEventRsvpStatus status) => switch (status) {
    AurenEventRsvpStatus.going => 'going', AurenEventRsvpStatus.interested => 'interested',
    AurenEventRsvpStatus.waitlisted => 'waitlisted', AurenEventRsvpStatus.cancelled => 'cancelled',
  };
  AurenEventRsvpStatus _statusFromString(String? status) => switch (status) {
    'going' => AurenEventRsvpStatus.going, 'interested' => AurenEventRsvpStatus.interested,
    'waitlisted' => AurenEventRsvpStatus.waitlisted, 'cancelled' => AurenEventRsvpStatus.cancelled,
    _ => throw const FormatException('Unknown RSVP status.'),
  };
}
