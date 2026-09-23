class ConversationId {
  const ConversationId._();

  /// Stable direct-message ID for the same pair of users.
  /// Sorting raw UIDs avoids hashCode collisions and keeps IDs deterministic.
  static String direct(String uidA, String uidB) {
    final a = uidA.trim();
    final b = uidB.trim();
    if (a.isEmpty || b.isEmpty || a == b) {
      throw ArgumentError('Two different user IDs are required.');
    }
    final members = [a, b]..sort();
    return 'dm_' + members[0] + '_' + members[1];
  }

  static String ai(String uid) {
    final value = uid.trim();
    if (value.isEmpty) {
      throw ArgumentError('A user ID is required.');
    }
    return 'ai_' + value;
  }
}