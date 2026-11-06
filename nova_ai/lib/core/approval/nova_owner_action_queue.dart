import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum NovaActionStatus {
  awaitingApproval,
  approved,
  rejected,
  running,
  completed,
  failed,
}

class NovaActionRequest {
  const NovaActionRequest({
    required this.id,
    required this.actionType,
    required this.summary,
    required this.createdAt,
    required this.status,
    required this.requiresOwnerApproval,
    this.reason,
    this.approvedAt,
    this.completedAt,
  });

  final String id;
  final String actionType;
  final String summary;
  final DateTime createdAt;
  final NovaActionStatus status;
  final bool requiresOwnerApproval;
  final String? reason;
  final DateTime? approvedAt;
  final DateTime? completedAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'actionType': actionType,
        'summary': summary,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'status': status.name,
        'requiresOwnerApproval': requiresOwnerApproval,
        'reason': reason,
        'approvedAt': approvedAt?.toUtc().toIso8601String(),
        'completedAt': completedAt?.toUtc().toIso8601String(),
      };

  static NovaActionRequest? fromJson(Object? value) {
    if (value is! Map) return null;
    try {
      final map = Map<String, Object?>.from(value);
      final id = map['id'];
      final actionType = map['actionType'];
      final summary = map['summary'];
      final createdAt = DateTime.tryParse('${map['createdAt'] ?? ''}');
      final statusName = map['status'];
      if (id is! String || id.isEmpty ||
          actionType is! String || actionType.isEmpty ||
          summary is! String || summary.isEmpty ||
          createdAt == null || statusName is! String) return null;
      final status = NovaActionStatus.values.where((v) => v.name == statusName);
      if (status.isEmpty) return null;
      DateTime? parseOptional(Object? raw) =>
          raw is String ? DateTime.tryParse(raw)?.toUtc() : null;
      return NovaActionRequest(
        id: id,
        actionType: actionType,
        summary: summary,
        createdAt: createdAt.toUtc(),
        status: status.first,
        requiresOwnerApproval: map['requiresOwnerApproval'] != false,
        reason: map['reason'] is String ? map['reason']! as String : null,
        approvedAt: parseOptional(map['approvedAt']),
        completedAt: parseOptional(map['completedAt']),
      );
    } catch (_) {
      return null;
    }
  }

  NovaActionRequest copyWith({
    NovaActionStatus? status,
    String? reason,
    DateTime? approvedAt,
    DateTime? completedAt,
  }) => NovaActionRequest(
        id: id,
        actionType: actionType,
        summary: summary,
        createdAt: createdAt,
        status: status ?? this.status,
        requiresOwnerApproval: requiresOwnerApproval,
        reason: reason ?? this.reason,
        approvedAt: approvedAt ?? this.approvedAt,
        completedAt: completedAt ?? this.completedAt,
      );
}

/// A local approval queue. It records decisions; it does not execute actions.
class NovaOwnerActionQueue {
  NovaOwnerActionQueue({
    SharedPreferences? preferences,
    this.storageKey = 'nova.action_queue.v1',
    this.maxRecords = 200,
  }) : _providedPreferences = preferences;

  final SharedPreferences? _providedPreferences;
  final String storageKey;
  final int maxRecords;

  Future<SharedPreferences> get _prefs async =>
      _providedPreferences ?? SharedPreferences.getInstance();

  Future<List<NovaActionRequest>> list() async {
    final raw = (await _prefs).getString(storageKey);
    if (raw == null) return <NovaActionRequest>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <NovaActionRequest>[];
      return decoded.map(NovaActionRequest.fromJson)
          .whereType<NovaActionRequest>().take(maxRecords).toList();
    } catch (_) {
      return <NovaActionRequest>[];
    }
  }

  Future<bool> _write(List<NovaActionRequest> records) async =>
      (await _prefs).setString(
        storageKey,
        jsonEncode(records.take(maxRecords).map((r) => r.toJson()).toList()),
      );

  Future<bool> enqueue({
    required String id,
    required String actionType,
    required String summary,
    required bool isReadOnly,
    bool externalSideEffect = false,
    bool sensitive = false,
  }) async {
    if (id.trim().isEmpty || actionType.trim().isEmpty || summary.trim().isEmpty) {
      return false;
    }
    final records = await list();
    if (records.any((r) => r.id == id)) return false;
    final needsApproval = !isReadOnly || externalSideEffect || sensitive;
    records.insert(0, NovaActionRequest(
      id: id,
      actionType: actionType,
      summary: summary,
      createdAt: DateTime.now().toUtc(),
      status: needsApproval
          ? NovaActionStatus.awaitingApproval
          : NovaActionStatus.approved,
      requiresOwnerApproval: needsApproval,
      approvedAt: needsApproval ? null : DateTime.now().toUtc(),
    ));
    return _write(records);
  }

  Future<bool> approve(String id, {required bool ownerConfirmed}) async {
    if (!ownerConfirmed) return false;
    return _transition(
      id,
      (record) => record.status == NovaActionStatus.awaitingApproval
          ? record.copyWith(
              status: NovaActionStatus.approved,
              approvedAt: DateTime.now().toUtc(),
            )
          : null,
    );
  }

  Future<bool> reject(String id, {required String reason}) async {
    if (reason.trim().isEmpty) return false;
    return _transition(
      id,
      (record) => record.status == NovaActionStatus.awaitingApproval
          ? record.copyWith(status: NovaActionStatus.rejected, reason: reason.trim())
          : null,
    );
  }

  Future<bool> claimForExecution(String id) async => _transition(
        id,
        (record) => record.status == NovaActionStatus.approved
            ? record.copyWith(status: NovaActionStatus.running)
            : null,
      );

  Future<bool> finish(String id, {required bool success}) async => _transition(
        id,
        (record) => record.status == NovaActionStatus.running
            ? record.copyWith(
                status: success ? NovaActionStatus.completed : NovaActionStatus.failed,
                completedAt: DateTime.now().toUtc(),
              )
            : null,
      );

  Future<bool> _transition(
    String id,
    NovaActionRequest? Function(NovaActionRequest) change,
  ) async {
    final records = await list();
    final index = records.indexWhere((record) => record.id == id);
    if (index < 0) return false;
    final updated = change(records[index]);
    if (updated == null) return false;
    records[index] = updated;
    return _write(records);
  }
}
