import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/everyday/appointment_draft_service.dart';

void main() {
  final fixedNow = DateTime(2026, 10, 20, 12);
  AurenAppointmentDraft make({
    String id = 'apt-1',
    String title = 'Dentist',
    DateTime? startsAt,
    DateTime? endsAt,
    AppointmentDraftStatus status = AppointmentDraftStatus.planned,
  }) => AurenAppointmentDraft(
    id: id,
    title: title,
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
    test('rejects invalid time range', () {
      expect(make(startsAt: DateTime(2026, 10, 21, 12),
        endsAt: DateTime(2026, 10, 21, 11)).validate(now: fixedNow), isNotNull);
    });
    test('rejects planned appointments in the past', () {
      expect(make(startsAt: DateTime(2026, 10, 19)).validate(now: fixedNow), isNotNull);
    });
    test('rejects excessive notes', () {
      expect(make().copyWith(status: AppointmentDraftStatus.planned)
        .validate(now: fixedNow), isNull);
      final oversized = AurenAppointmentDraft(
        id: 'apt-2', title: 'Check-up', startsAt: DateTime(2026, 10, 21),
        notes: 'x' * 2001,
      );
      expect(oversized.validate(now: fixedNow), isNotNull);
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
