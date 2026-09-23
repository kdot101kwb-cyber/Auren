import 'package:cloud_functions/cloud_functions.dart';

import '../../core/models/ai_response.dart';
import 'ai_gateway.dart';

class FirebaseAurenAiGateway implements AurenAiGateway {
  final FirebaseFunctions _functions;

  FirebaseAurenAiGateway({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  @override
  Future<AurenAiResponse> send({
    required String conversationId,
    required String message,
    String? requestId,
  }) async {
    final callable = _functions.httpsCallable('aurenAiGateway');
    final result = await callable.call(<String, dynamic>{
      'conversationId': conversationId,
      'message': message,
      'requestId': requestId,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final rawPayload = data['payload'];
    return AurenAiResponse(
      text: data['text'] as String? ?? '',
      action: data['action'] as String?,
      payload: rawPayload is Map ? Map<String, dynamic>.from(rawPayload) : const {},
      requiresApproval: data['requiresApproval'] as bool? ?? false,
    );
  }
}
