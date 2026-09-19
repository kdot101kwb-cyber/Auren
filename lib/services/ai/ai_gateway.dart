import '../../core/models/ai_response.dart';

abstract interface class AurenAiGateway {
  Future<AurenAiResponse> send({
    required String conversationId,
    required String message,
  });
}

class LocalAiGateway implements AurenAiGateway {
  @override
  Future<AurenAiResponse> send({
    required String conversationId,
    required String message,
  }) async {
    return AurenAiResponse(
      text: 'وصلتني رسالتك: "$message". أنا AUREN AI، وجاهز أساعدك خطوة بخطوة.',
    );
  }
}
