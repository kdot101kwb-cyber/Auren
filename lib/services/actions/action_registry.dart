import '../../core/models/action_request.dart';

enum AurenRiskLevel { low, medium, high, critical }

enum AurenPermission {
  readOnly,
  standard,
  userApproval,
  financial,
  accountSensitive,
}

class AurenActionDefinition {
  final String type;
  final String title;
  final AurenRiskLevel riskLevel;
  final AurenPermission permission;
  final int approvalLevel;
  final bool requiresApproval;
  final int? maxAmountMinor;
  final Set<String> allowedPayloadKeys;

  const AurenActionDefinition({
    required this.type,
    required this.title,
    required this.riskLevel,
    required this.permission,
    required this.approvalLevel,
    required this.requiresApproval,
    this.maxAmountMinor,
    this.allowedPayloadKeys = const {},
  });
}

class AurenActionRegistry {
  static const definitions = <String, AurenActionDefinition>{
    'demo.echo': AurenActionDefinition(
      type: 'demo.echo',
      title: 'Echo',
      riskLevel: AurenRiskLevel.low,
      permission: AurenPermission.userApproval,
      approvalLevel: 1,
      requiresApproval: true,
      allowedPayloadKeys: {'text'},
    ),
    'demo.create_note': AurenActionDefinition(
      type: 'demo.create_note',
      title: 'Create note',
      riskLevel: AurenRiskLevel.low,
      permission: AurenPermission.userApproval,
      approvalLevel: 1,
      requiresApproval: true,
      allowedPayloadKeys: {'text'},
    ),
    'memory.save': AurenActionDefinition(
      type: 'memory.save',
      title: 'Save AI memory',
      riskLevel: AurenRiskLevel.low,
      permission: AurenPermission.userApproval,
      approvalLevel: 1,
      requiresApproval: true,
      allowedPayloadKeys: {'key', 'value'},
    ),
  };

  static bool isPayloadAllowed(String type, Map<String, dynamic> payload) {
    final definition = get(type);
    if (definition == null) return false;
    return payload.keys.every(definition.allowedPayloadKeys.contains);
  }

  static AurenActionDefinition? get(String type) => definitions[type];

  static AurenActionRequest fromAi({
    required String id,
    required String conversationId,
    required String actionType,
    required String title,
    required String description,
    Map<String, dynamic> payload = const {},
    required DateTime createdAt,
  }) {
    final normalizedType = actionType.trim().toLowerCase();
    final definition = get(normalizedType);
    if (definition == null) {
      throw StateError('Unknown AUREN action type: $actionType');
    }
    if (normalizedType != actionType || normalizedType.length > 80) {
      throw StateError('Invalid AUREN action type.');
    }
    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();
    if (normalizedDescription.length > 2000) {
      throw StateError('Action description is too long.');
    }
    final invalidKeys = payload.keys
        .where((key) => !definition.allowedPayloadKeys.contains(key));
    if (invalidKeys.isNotEmpty) {
      throw StateError('Unsupported action payload.');
    }
    return AurenActionRequest(
      id: id,
      conversationId: conversationId,
      actionType: normalizedType,
      title: normalizedTitle.isEmpty ? definition.title : normalizedTitle,
      description: normalizedDescription,
      payload: Map<String, dynamic>.from(payload),
      permission: definition.permission.name,
      riskLevel: definition.riskLevel.name,
      approvalLevel: definition.approvalLevel,
      spendingLimitMinor: definition.maxAmountMinor,
      requiresApproval: definition.requiresApproval,
      status: 'pending',
      createdAt: createdAt,
    );
  }
}
