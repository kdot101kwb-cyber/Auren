/// Short-lived consent granted after a clear, user-facing confirmation.
///
/// Call [fromUserConfirmation] only from a UI flow where the user has just
/// accepted sharing health check-ins with the remote service. The consent is
/// deliberately not persisted; callers must obtain it again for a new session.
class HealthDataSharingConsent {
  HealthDataSharingConsent._({
    required this.purpose,
    required this.grantedAt,
  });

  static const maxAge = Duration(minutes: 15);
  static const _clockSkewAllowance = Duration(seconds: 30);

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

  /// Rejects stale, future-dated, or malformed consent before remote access.
  void validateForUse({DateTime? now}) {
    if (purpose.trim().isEmpty || purpose.length > 160) {
      throw StateError('Health data sharing consent is invalid.');
    }
    final current = (now ?? DateTime.now()).toUtc();
    final age = current.difference(grantedAt.toUtc());
    if (age < -_clockSkewAllowance || age > maxAge) {
      throw StateError('Health data sharing consent has expired.');
    }
  }
}
