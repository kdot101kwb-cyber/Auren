class AurenAgentCredential {
  final String credentialId;
  final String agentId;
  final String scheme;
  final String status;
  final DateTime createdAt;

  const AurenAgentCredential({
    required this.credentialId,
    required this.agentId,
    required this.scheme,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'credentialId': credentialId,
        'agentId': agentId,
        'scheme': scheme,
        'status': status,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}
