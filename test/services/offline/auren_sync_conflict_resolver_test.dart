import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/offline/auren_sync_conflict_resolver.dart';

void main() {
  test('merges independent local and remote field changes', () {
    final result = AurenSyncConflictResolver.merge(
      base: {'title': 'old', 'done': false},
      local: {'title': 'local', 'done': false},
      remote: {'title': 'old', 'done': true},
    );
    expect(result.merged, {'title': 'local', 'done': true});
    expect(result.hasConflicts, isFalse);
  });

  test('preserves local draft and reports same-field conflict', () {
    final result = AurenSyncConflictResolver.merge(
      base: {'title': 'old'},
      local: {'title': 'local'},
      remote: {'title': 'remote'},
    );
    expect(result.merged['title'], 'local');
    expect(result.conflicts, {'title'});
  });

  test('respects deletion and structurally equal nested values', () {
    final result = AurenSyncConflictResolver.merge(
      base: {'remove': 1, 'nested': {'a': [1, 2]}},
      local: {'nested': {'a': [1, 2]}},
      remote: {'remove': 1, 'nested': {'a': [1, 2]}},
    );
    expect(result.merged.containsKey('remove'), isFalse);
    expect(result.hasConflicts, isFalse);
  });
}
