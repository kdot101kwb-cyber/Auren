import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/everyday/appointment_draft_service.dart';

void main() {
  final fixedNow = DateTime(2026, 10, 20, 12);
  AurenAppointmentDraft make({
    String id = 'apt-1',
    String title = 'Dentist',
    String? providerName,
    String? location,
    String notes = '',
    DateTime? startsAt,
    DateTime? endsAt,
    AppointmentDraftStatus status = AppointmentDraftStatus.planned,
  }) => AurenAppointmentDraft(
    id: id,
    title: title,
    providerName: providerName,
    location: location,
    notes: notes,
    startsAt: startsAt ?? DateTime(2026, 10, 21, 12),
    endsAt: endsAt,
    status: status,
  );

  group('AurenAppointmentDraft validation', () {
    test('accepts a valid future draft without claiming booking confirmation', () {
      expect(make().validate(now: fixedNow), isNull);
    });

    test('rejects missing id and title', () {
      expect(make(id: ' ').validate(now: fixedNow), isNotNull);
      expect(make(title: ' ').validate(now: fixedNow), isNotNull);
    });

    test('rejects overlong title, provider, and location fields', () {
      expect(make(title: List.filled(121, 't').join()).validate(now: fixedNow), isNotNull);
      expect(make(providerName: List.filled(121, 'p').join()).validate(now: fixedNow), isNotNull);
      expect(make(location: List.filled(301, 'l').join()).validate(now: fixedNow), isNotNull);
    });

    test('rejects equal or reversed appointment time ranges', () {
      final start = DateTime(2026, 10, 21, 12);
      expect(make(startsAt: start, endsAt: start).validate(now: fixedNow), isNotNull);
      expect(make(startsAt: start, endsAt: start.subtract(const Duration(minutes: 1)))
          .validate(now: fixedNow), isNotNull);
    });

    test('rejects planned appointments in the past', () {
      expect(make(startsAt: DateTime(2026, 10, 19)).validate(now: fixedNow), isNotNull);
    });

    test('allows historical appointments already marked completed', () {
      expect(make(
        startsAt: DateTime(2026, 10, 19),
        status: AppointmentDraftStatus.completed,
      ).validate(now: fixedNow), isNull);
    });

    test('rejects excessive notes and accepts notes at the limit', () {
      expect(make(notes: List.filled(2000, 'x').join()).validate(now: fixedNow), isNull);
      expect(make(notes: List.filled(2001, 'x').join()).validate(now: fixedNow), isNotNull);
    });
  });

  group('AurenAppointmentDraftPolicy', () {
    test('allows planned to completed or cancelled', () {
      expect(AurenAppointmentDraftPolicy.canTransition(
        AppointmentDraftStatus.planned, AppointmentDraftStatus.completed), isTrue);
      expect(AurenAppointmentDraftPolicy.canTransition(
        AppointmentDraftStatus.planned, AppointmentDraftStatus.cancelled), isTrue);
    });

    test('does not reopen terminal states', () {
      expect(AurenAppointmentDraftPolicy.canTransition(
        AppointmentDraftStatus.cancelled, AppointmentDraftStatus.planned), isFalse);
      expect(AurenAppointmentDraftPolicy.canTransition(
        AppointmentDraftStatus.completed, AppointmentDraftStatus.planned), isFalse);
    });

    test('throws on an invalid transition', () {
      expect(() => AurenAppointmentDraftPolicy.transition(
        make(status: AppointmentDraftStatus.cancelled),
        AppointmentDraftStatus.planned,
      ), throwsStateError);
    });
  });
}
