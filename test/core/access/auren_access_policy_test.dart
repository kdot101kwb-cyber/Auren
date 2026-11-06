import 'package:flutter_test/flutter_test.dart';
import 'package:auren/core/access/auren_access_policy.dart';

void main() {
  test('unknown and malformed roles fail closed to guest', () {
    expect(AurenAccessPolicy.roleFromClaim('root'), AurenRole.guest);
    expect(AurenAccessPolicy.roleFromClaim(null), AurenRole.guest);
    expect(AurenAccessPolicy.allows(AurenRole.guest, AurenPermission.managePlatformSettings), isFalse);
  });

  test('permissions increase only through explicit role grants', () {
    expect(AurenAccessPolicy.allows(AurenRole.member, AurenPermission.createCommunityPost), isTrue);
    expect(AurenAccessPolicy.allows(AurenRole.member, AurenPermission.moderateCommunityContent), isFalse);
    expect(AurenAccessPolicy.allows(AurenRole.moderator, AurenPermission.moderateCommunityContent), isTrue);
  });

  test('session validation requires a user and future expiry', () {
    final now = DateTime.utc(2026, 1, 1);
    expect(AurenAccessPolicy.sessionIsValid(now: now, expiresAt: now.add(const Duration(seconds: 1)), userId: 'u1'), isTrue);
    expect(AurenAccessPolicy.sessionIsValid(now: now, expiresAt: now, userId: 'u1'), isFalse);
    expect(AurenAccessPolicy.sessionIsValid(now: now, expiresAt: now.add(const Duration(days: 1)), userId: ' '), isFalse);
    expect(AurenAccessPolicy.sessionIsValid(now: now, expiresAt: null, userId: 'u1'), isFalse);
  });
}
