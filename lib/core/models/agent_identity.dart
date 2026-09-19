class AurenAgentIdentity {
  final String agentId;
  final String name;
  final String version;
  final String ownerUid;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AurenAgentIdentity({
    required this.agentId,
    required this.name,
    required this.version,
    required this.ownerUid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'agentId': agentId,
        'name': name,
        'version': version,
        'ownerUid': ownerUid,
        'status': status,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };
}
