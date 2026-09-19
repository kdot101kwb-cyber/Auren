class AurenAgentPermission {
  final String agentId;
  final bool enabled;
  final Set<String> allowedActions;
  final int? dailySpendingLimitMinor;
  final int spentTodayMinor;
  final String currency;
  final DateTime updatedAt;

  const AurenAgentPermission({
    required this.agentId,
    required this.enabled,
    this.allowedActions = const {},
    this.dailySpendingLimitMinor,
    this.spentTodayMinor = 0,
    this.currency = 'USD',
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'agentId': agentId,
        'enabled': enabled,
        'allowedActions': allowedActions.toList(),
        'dailySpendingLimitMinor': dailySpendingLimitMinor,
        'spentTodayMinor': spentTodayMinor,
        'currency': currency,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };
}
