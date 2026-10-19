import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/profile_privacy/domain/profile_visibility_projection.dart';

void main() {
  const policy = AurenProfileVisibilityPolicy({
    'headline': AurenFieldVisibility.public,
    'bio': AurenFieldVisibility.followers,
    'privateNotes': AurenFieldVisibility.private,
    'circlePhotos': AurenFieldVisibility.closeFriends,
  });

  group('AurenProfileVisibilityPolicy.canView', () {
    test('allows only fields matching the viewer audience', () {
      expect(policy.canView(field: 'headline', audience: AurenViewerAudience.public, blocked: false), isTrue);
      expect(policy.canView(field: 'bio', audience: AurenViewerAudience.public, blocked: false), isFalse);
      expect(policy.canView(field: 'bio', audience: AurenViewerAudience.followers, blocked: false), isTrue);
      expect(policy.canView(field: 'circlePhotos', audience: AurenViewerAudience.followers, blocked: false), isFalse);
      expect(policy.canView(field: 'circlePhotos', audience: AurenViewerAudience.closeFriends, blocked: false), isTrue);
    });

    test('fails closed for unknown and empty fields', () {
      expect(policy.canView(field: 'unlisted', audience: AurenViewerAudience.public, blocked: false), isFalse);
      expect(policy.canView(field: ' ', audience: AurenViewerAudience.public, blocked: false), isFalse);
    });

    test('owner can view their fields but blocked viewers cannot', () {
      expect(policy.canView(field: 'privateNotes', audience: AurenViewerAudience.owner, blocked: false), isTrue);
      expect(policy.canView(field: 'headline', audience: AurenViewerAudience.owner, blocked: true), isFalse);
    });
  });

  group('AurenProfileVisibilityPolicy.project', () {
    const data = <String, Object?>{
      'headline': 'Public headline',
      'bio': 'Followers-only bio',
      'privateNotes': 'Secret',
      'unlisted': 'No policy',
      'circlePhotos': ['private photo'],
    };

    test('omits private and unknown fields from public projection', () {
      final projected = policy.project(
        data: data,
        audience: AurenViewerAudience.public,
        blocked: false,
      );
      expect(projected, {'headline': 'Public headline'});
      expect(data['privateNotes'], 'Secret');
    });

    test('keeps follower and close-friend fields only for eligible viewers', () {
      final followers = policy.project(
        data: data,
        audience: AurenViewerAudience.followers,
        blocked: false,
      );
      expect(followers.keys, containsAll(['headline', 'bio']));
      expect(followers.keys, isNot(contains('privateNotes')));
      final friends = policy.project(
        data: data,
        audience: AurenViewerAudience.closeFriends,
        blocked: false,
      );
      expect(friends.keys, containsAll(['headline', 'bio', 'circlePhotos']));
    });

    test('returns no data for blocked viewers and all data for owner', () {
      expect(policy.project(data: data, audience: AurenViewerAudience.public, blocked: true), isEmpty);
      expect(policy.project(data: data, audience: AurenViewerAudience.owner, blocked: false), data);
    });
  });
}
