import 'package:flutter/foundation.dart';

/// A user-authored appointment plan, not a confirmed external booking.
///
/// External confirmation must only be attached by a trusted provider adapter.
@immutable
class AurenAppointmentDraft {
  final String id;
  final String title;
  final String? providerName;
  final String? location;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String notes;
  final AppointmentDraftStatus status;

  const AurenAppointmentDraft({
    required this.id,
    required this.title,
    required this.startsAt,
    this.endsAt,
    this.providerName,
    this.location,
    this.notes = '',
    this.status = AppointmentDraftStatus.planned,
  });

  AurenAppointmentDraft copyWith({AppointmentDraftStatus? status}) =>
      AurenAppointmentDraft(
        id: id,
        title: title,
        providerName: providerName,
        location: location,
        startsAt: startsAt,
        endsAt: endsAt,
        notes: notes,
        status: status ?? this.status,
      );

  /// Validates user input before it is persisted by an authenticated repository.
  /// No provider is contacted and no booking is created by this model.
  String? validate({DateTime? now}) {
    if (id.trim().isEmpty) return 'Appointment id is required.';
    if (title.trim().isEmpty) return 'Appointment title is required.';
    if (title.trim().length > 120) return 'Appointment title is too long.';
    if (notes.length > 2000) return 'Notes are too long.';
    if ((providerName?.length ?? 0) > 120) return 'Provider name is too long.';
    if ((location?.length ?? 0) > 300) return 'Location is too long.';
    if (endsAt != null && !endsAt!.isAfter(startsAt)) {
      return 'End time must be after start time.';
    }
    if (startsAt.isBefore((now ?? DateTime.now()).subtract(const Duration(minutes: 1))) &&
        status == AppointmentDraftStatus.planned) {
      return 'A new planned appointment cannot start in the past.';
    }
    return null;
  }
}

enum AppointmentDraftStatus { planned, completed, cancelled }

/// Deliberately restrictive lifecycle: terminal states cannot be reopened silently.
class AurenAppointmentDraftPolicy {
  const AurenAppointmentDraftPolicy._();

  static bool canTransition(
    AppointmentDraftStatus from,
    AppointmentDraftStatus to,
  ) {
    if (from == to) return true;
    switch (from) {
      case AppointmentDraftStatus.planned:
        return to == AppointmentDraftStatus.completed ||
            to == AppointmentDraftStatus.cancelled;
      case AppointmentDraftStatus.completed:
      case AppointmentDraftStatus.cancelled:
        return false;
    }
  }

  static AurenAppointmentDraft transition(
    AurenAppointmentDraft draft,
    AppointmentDraftStatus to,
  ) {
    if (!canTransition(draft.status, to)) {
      throw StateError('Invalid appointment status transition: ${draft.status} -> $to');
    }
    return draft.copyWith(status: to);
  }
}
