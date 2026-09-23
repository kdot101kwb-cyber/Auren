import '../../core/models/ai_response.dart';
import 'firebase_ai_gateway.dart';

abstract interface class AurenAiGateway {
  Future<AurenAiResponse> send({
    required String conversationId,
    required String message,
    String? requestId,
  });
}

class LocalAiGateway implements AurenAiGateway {
  @override
  Future<AurenAiResponse> send({
    required String conversationId,
    required String message,
    String? requestId,
  }) async {
    return AurenAiResponse(
      text: 'وصلتني رسالتك: "$message". أنا AUREN AI، وجاهز أساعدك خطوة بخطوة.',
    );
  }
}

/// Uses the real authenticated AI gateway when configured, while keeping
/// development/offline builds usable when no endpoint is supplied.
class ResilientAurenAiGateway implements AurenAiGateway {
  final AurenAiGateway remote;
  final AurenAiGateway fallback;

  ResilientAurenAiGateway({
    AurenAiGateway? remote,
    AurenAiGateway? fallback,
  })  : remote = remote ?? FirebaseAurenAiGateway(),
        fallback = fallback ?? LocalAiGateway();

  @override
  Future<AurenAiResponse> send({
    required String conversationId,
    required String message,
    String? requestId,
  }) async {
    try {
      return await remote.send(
        conversationId: conversationId,
        message: message,
        requestId: requestId,
      );
    } on StateError {
      return fallback.send(
        conversationId: conversationId,
        message: message,
      );
    }
  }
}
