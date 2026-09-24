class AurenMemoryItem {
  final String id, key, value;
  final bool enabled;
  final DateTime updatedAt;

  const AurenMemoryItem({
    required this.id,
    required this.key,
    required this.value,
    required this.enabled,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'key': key,
        'value': value,
        'enabled': enabled,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  factory AurenMemoryItem.fromMap(String id, Map<String, dynamic> m) =>
      AurenMemoryItem(
        id: id,
        key: m['key']?.toString() ?? '',
        value: m['value']?.toString() ?? '',
        enabled: m['enabled'] is bool ? m['enabled'] as bool : true,
        updatedAt: _parseDate(m['updatedAt']),
      );
}
