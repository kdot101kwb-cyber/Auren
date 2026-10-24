/// Authorization policy helpers. Authentication remains owned by FirebaseAurenAuthService.
enum AurenRole { guest, member, moderator, administrator }
enum AurenPermission {
  readOwnData,
  editOwnData,
  createCommunityPost,
  moderateCommunityContent,
  manageCommunityMembers,
  managePlatformSettings,
}

class AurenAccessPolicy {
  const AurenAccessPolicy._();

  static const Map<AurenRole, Set<AurenPermission>> _grants = {
    AurenRole.guest: {AurenPermission.readOwnData},
    AurenRole.member: {
      AurenPermission.readOwnData,
      AurenPermission.editOwnData,
      AurenPermission.createCommunityPost,
    },
    AurenRole.moderator: {
      AurenPermission.readOwnData,
      AurenPermission.editOwnData,
      AurenPermission.createCommunityPost,
      AurenPermission.moderateCommunityContent,
    },
    AurenRole.administrator: AurenPermission.values.toSet(),
  };

  static bool allows(AurenRole role, AurenPermission permission) =>
      _grants[role]?.contains(permission) ?? false;

  /// Fail closed when a role string is absent, malformed, or unknown.
  static AurenRole roleFromClaim(Object? value) {
    if (value is! String) return AurenRole.guest;
    return AurenRole.values.where((role) => role.name == value).firstOrNull ??
        AurenRole.guest;
  }

  static bool sessionIsValid({
    required DateTime now,
    required DateTime? expiresAt,
    required String? userId,
  }) {
    if (userId == null || userId.trim().isEmpty || expiresAt == null) return false;
    return expiresAt.isAfter(now);
  }
}
