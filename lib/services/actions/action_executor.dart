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

abstract interface class AurenActionExecutor {
  Future<AurenActionExecutionResult> execute({
    required String uid,
    required AurenActionRequest action,
  });
}

/// Executes user-approved actions through Firebase, so the client never gets
/// direct authority to perform a privileged action.
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

    final callable = _functions.httpsCallable('executeAurenAction');
    final response = await callable.call(<String, dynamic>{
      'actionId': action.id,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return AurenActionExecutionResult(
      result: data['result'] as String? ?? 'تم تنفيذ الأمر.',
      status: data['status'] as String? ?? 'completed',
    );
  }
}
