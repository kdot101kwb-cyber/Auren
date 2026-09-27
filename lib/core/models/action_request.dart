import 'package:cloud_firestore/cloud_firestore.dart';

class AurenActionRequest {
  final String id;
  final String conversationId;
  final String actionType;
  final String title;
  final String description;
  final Map<String, dynamic> payload;
  final String permission;
  final String riskLevel;
  final int approvalLevel;
  final int? spendingLimitMinor;
  final String? currency;
  final bool requiresApproval;
  final String status;
  final dynamic result;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? executionStartedAt;
  final String? executionSpendingDay;

  const AurenActionRequest({
    required this.id,
    required this.conversationId,
    required this.actionType,
    required this.title,
    required this.description,
    this.payload = const {},
    this.permission = 'standard',
    this.riskLevel = 'low',
    this.approvalLevel = 1,
    this.spendingLimitMinor,
    this.currency,
    required this.requiresApproval,
    required this.status,
    this.result,
    required this.createdAt,
    this.expiresAt,
    this.executionStartedAt,
    this.executionSpendingDay,
  });

  Map<String, dynamic> toMap() => {
        'conversationId': conversationId,
        'actionType': actionType,
        'title': title,
        'description': description,
        'payload': payload,
        'permission': permission,
        'riskLevel': riskLevel,
        'approvalLevel': approvalLevel,
        'spendingLimitMinor': spendingLimitMinor,
        'currency': currency,
        'requiresApproval': requiresApproval,
        'status': status,
        'result': result,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'expiresAt': expiresAt?.toUtc().toIso8601String(),
        'executionStartedAt': executionStartedAt?.toUtc().toIso8601String(),
        'executionSpendingDay': executionSpendingDay,
      };

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static Map<String, dynamic> _parsePayload(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  factory AurenActionRequest.fromMap(String id, Map<String, dynamic> m) =>
      AurenActionRequest(
        id: id,
        conversationId: m['conversationId'] as String? ?? '',
        actionType: m['actionType'] as String? ?? 'unknown',
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        payload: _parsePayload(m['payload']),
        permission: m['permission'] as String? ?? 'standard',
        riskLevel: m['riskLevel'] as String? ?? 'low',
        approvalLevel: (m['approvalLevel'] as num?)?.toInt() ?? 1,
        spendingLimitMinor: (m['spendingLimitMinor'] as num?)?.toInt(),
        currency: m['currency'] as String?,
        requiresApproval: m['requiresApproval'] as bool? ?? true,
        status: m['status'] as String? ?? 'pending',
        result: m['result'],
        createdAt: _parseDate(m['createdAt']),
        expiresAt: m['expiresAt'] == null
            ? (m['expiresAtMs'] is num ? DateTime.fromMillisecondsSinceEpoch((m['expiresAtMs'] as num).toInt(), isUtc: true) : null)
            : _parseDate(m['expiresAt']),
        executionStartedAt: m['executionStartedAt'] == null ? null : _parseDate(m['executionStartedAt']),
        executionSpendingDay: m['executionSpendingDay'] as String?,
      );
}
