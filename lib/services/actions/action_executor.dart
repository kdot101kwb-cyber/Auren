import 'package:cloud_functions/cloud_functions.dart';

import '../../core/models/action_request.dart';

class AurenActionExecutionResult {
  final String result;
  final String status;

  const AurenActionExecutionResult({
    required this.result,
    required this.status,
  });
}

/// Executes user-approved actions through the trusted Firebase backend.
class FirebaseAurenActionExecutor implements AurenActionExecutor {
  final FirebaseFunctions _functions;

  FirebaseAurenActionExecutor({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  @override
  Future<AurenActionExecutionResult> execute({
    required String uid,
    required AurenActionRequest action,
  }) async {
    if (action.status != 'approved') {
      throw StateError('Action must be approved before execution.');
    }

    final response = await _functions
        .httpsCallable('executeAurenAction')
        .call(<String, dynamic>{'actionId': action.id});

    final data = Map<String, dynamic>.from(response.data as Map);
    return AurenActionExecutionResult(
      result: _friendlyResult(data['result']),
      status: data['status'] as String? ?? 'completed',
    );
  }

  Future<AurenActionExecutionResult> recover({
    required String uid,
    required AurenActionRequest action,
  }) async {
    if (action.status != 'executing') {
      throw StateError('Only an executing action can be recovered.');
    }
    final response = await _functions
        .httpsCallable('recoverAurenAction')
        .call(<String, dynamic>{'actionId': action.id});
    final data = Map<String, dynamic>.from(response.data as Map);
    return AurenActionExecutionResult(
      result: _friendlyResult(data['result']),
      status: data['status'] as String? ?? 'completed',
    );
  }

  String _friendlyResult(dynamic result) {
    if (result is String) return result;
    if (result is Map) {
      final type = result['type'];
      switch (type) {
        case 'note_created':
          return 'تم إنشاء الملاحظة بنجاح.';
        case 'memory_saved':
          return 'تم حفظ المعلومة في ذاكرة AUREN.';
        case 'echo':
          return (result['text'] as String?)?.trim().isNotEmpty == true
              ? result['text'] as String
              : 'تم تنفيذ الطلب بنجاح.';
        case 'supplier_contact_draft_created':
          final requestId = result['requestId']?.toString().trim() ?? '';
          return requestId.isEmpty
              ? 'تم إنشاء مسودة التواصل مع المورد. لم يتم إرسالها.'
              : 'تم إنشاء مسودة التواصل مع المورد. رقم المسودة: $requestId. لم يتم إرسالها.';
        case 'supplier_rfq_created':
          final rfqId = result['rfqId']?.toString().trim() ?? '';
          return rfqId.isEmpty
              ? 'تم إنشاء مسودة طلب عرض السعر. لم يتم إرسالها.'
              : 'تم إنشاء مسودة طلب عرض السعر. رقم المسودة: $rfqId. لم يتم إرسالها.';
      }
    }
    return 'تم تنفيذ الأمر بنجاح.';
  }
}

abstract interface class AurenActionExecutor {
  Future<AurenActionExecutionResult> execute({
    required String uid,
    required AurenActionRequest action,
  });

  Future<AurenActionExecutionResult> recover({
    required String uid,
    required AurenActionRequest action,
  });
}
