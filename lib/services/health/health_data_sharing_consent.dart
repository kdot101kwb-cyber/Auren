/// Short-lived consent granted after a clear, user-facing confirmation.
///
/// Call [fromUserConfirmation] only from a UI flow where the user has just
/// accepted sharing health check-ins with the remote service. The consent is
/// deliberately not persisted here; callers must obtain it again for a new
/// sharing session.
class HealthDataSharingConsent {
  HealthDataSharingConsent._({
    required this.purpose,
    required this.grantedAt,
  });

  final String purpose;
  final DateTime grantedAt;

  factory HealthDataSharingConsent.fromUserConfirmation({
    required bool accepted,
    required String purpose,
    DateTime? grantedAt,
  }) {
    if (!accepted) {
      throw StateError('Health data sharing requires explicit user confirmation.');
    }
    final normalizedPurpose = purpose.trim();
    if (normalizedPurpose.isEmpty || normalizedPurpose.length > 160) {
      throw ArgumentError.value(
        purpose,
        'purpose',
        'must contain 1–160 characters',
      );
    }
    return HealthDataSharingConsent._(
      purpose: normalizedPurpose,
      grantedAt: (grantedAt ?? DateTime.now()).toUtc(),
    );
  }
}
