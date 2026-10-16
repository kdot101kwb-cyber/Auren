import 'package:flutter/foundation.dart';

/// Explicit publication policy for fields in a profile mode.
///
/// Missing field policies are private by default. This is a client-side
/// projection only; Firestore rules must separately prevent direct reads of
/// unpublished source documents.
enum AurenFieldVisibility { private, closeFriends, followers, public }

enum AurenViewerAudience { owner, closeFriends, followers, public }

@immutable
class AurenProfileVisibilityPolicy {
  const AurenProfileVisibilityPolicy(this.fields);

  /// Field name -> visibility. Duplicate/unknown fields are not inferred.
  final Map<String, AurenFieldVisibility> fields;

  bool canView({
    required String field,
    required AurenViewerAudience audience,
    required bool blocked,
  }) {
    if (blocked || field.trim().isEmpty) return false;
    if (audience == AurenViewerAudience.owner) return true;
    final visibility = fields[field];
    if (visibility == null) return false;
    switch (visibility) {
      case AurenFieldVisibility.private:
        return false;
      case AurenFieldVisibility.closeFriends:
        return audience == AurenViewerAudience.closeFriends;
      case AurenFieldVisibility.followers:
        return audience == AurenViewerAudience.closeFriends ||
            audience == AurenViewerAudience.followers;
      case AurenFieldVisibility.public:
        return true;
    }
  }

  /// Creates a safe display projection without mutating the original data.
  /// Unknown fields and fields without an explicit policy are omitted.
  Map<String, Object?> project({
    required Map<String, Object?> data,
    required AurenViewerAudience audience,
    required bool blocked,
  }) {
    if (blocked) return const <String, Object?>{};
    if (audience == AurenViewerAudience.owner) {
      return Map<String, Object?>.unmodifiable(data);
    }
    return Map<String, Object?>.unmodifiable({
      for (final entry in data.entries)
        if (canView(field: entry.key, audience: audience, blocked: false))
          entry.key: entry.value,
    });
  }
}
