enum RiskLevel { low, medium, high, critical }

enum InterfaceComplexity { simple2D, adaptive2_5D, spatialGraph }

class ActionDefinition {
  final String actionId;
  final String titleKey;
  final String descriptionKey;
  final String iconName;
  final RiskLevel riskLevel;
  final InterfaceComplexity defaultUiComplexity;
  final bool requiresHumanApproval;
  final List<String> requiredPermissions;

  const ActionDefinition({
    required this.actionId,
    required this.titleKey,
    required this.descriptionKey,
    required this.iconName,
    required this.riskLevel,
    required this.defaultUiComplexity,
    required this.requiresHumanApproval,
    this.requiredPermissions = const [],
  });
}