/// Pure, deterministic three-way merge for JSON-like local records.
///
/// Values changed on only one side are retained. Concurrent edits to the same
/// field are surfaced as conflicts instead of silently overwriting user data.
class AurenSyncConflictResult {
  const AurenSyncConflictResult({
    required this.merged,
    required this.conflicts,
  });

  final Map<String, Object?> merged;
  final Set<String> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;
}

class AurenSyncConflictResolver {
  const AurenSyncConflictResolver._();

  static AurenSyncConflictResult merge({
    required Map<String, Object?> base,
    required Map<String, Object?> local,
    required Map<String, Object?> remote,
  }) {
    final keys = <String>{...base.keys, ...local.keys, ...remote.keys};
    final merged = <String, Object?>{};
    final conflicts = <String>{};

    for (final key in keys) {
      final original = base[key];
      final localValue = local[key];
      final remoteValue = remote[key];
      final localChanged = !_same(localValue, original) || local.containsKey(key) != base.containsKey(key);
      final remoteChanged = !_same(remoteValue, original) || remote.containsKey(key) != base.containsKey(key);

      if (localChanged && remoteChanged && !_same(localValue, remoteValue)) {
        conflicts.add(key);
        // Keep local value as the visible draft; callers must resolve explicitly.
        if (local.containsKey(key)) merged[key] = localValue;
      } else if (localChanged) {
        if (local.containsKey(key)) merged[key] = localValue;
      } else if (remoteChanged) {
        if (remote.containsKey(key)) merged[key] = remoteValue;
      } else if (base.containsKey(key)) {
        merged[key] = original;
      }
    }

    return AurenSyncConflictResult(
      merged: Map.unmodifiable(merged),
      conflicts: Set.unmodifiable(conflicts),
    );
  }

  static bool _same(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_same(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_same(a[key], b[key])) return false;
      }
      return true;
    }
    return a == b;
  }
}
