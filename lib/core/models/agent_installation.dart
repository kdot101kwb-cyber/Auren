class AurenAgentInstallation {
  final String agentId;
  final String name;
  final String version;
  final String status;
  final DateTime installedAt;

  const AurenAgentInstallation({
    required this.agentId,
    required this.name,
    required this.version,
    required this.status,
    required this.installedAt,
  });

  Map<String, dynamic> toMap() => {
    'agentId': agentId,
    'name': name,
    'version': version,
    'status': status,
    'installedAt': installedAt.toIso8601String(),
  };

  factory AurenAgentInstallation.fromMap(Map<String, dynamic> m) =>
      AurenAgentInstallation(
        agentId: m['agentId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        version: m['version'] as String? ?? '1.0',
        status: m['status'] as String? ?? 'active',
        installedAt: DateTime.tryParse(m['installedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
