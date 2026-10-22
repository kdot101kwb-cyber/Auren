import '../../core/models/ai_response.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'firebase_ai_gateway.dart';

abstract interface class AurenAiGateway {
  Future<AurenAiResponse> send({
    required String conversationId,
    required String message,
    String? requestId,
    bool includePersonalContext = false,
  });
}

/// Only errors of this type are eligible for the local fallback response.
class AurenAiFallbackEligibleException implements Exception {
  const AurenAiFallbackEligibleException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalAiGateway implements AurenAiGateway {
  @override
  Future<AurenAiResponse> send({
    required String conversationId,
    required String message,
    String? requestId,
    bool includePersonalContext = false,
  }) async {
    return AurenAiResponse(
      text: 'وصلتني رسالتك: "$message". أنا AUREN AI، وجاهز أساعدك خطوة بخطوة.',
    );
  }
}

/// Uses the authenticated AI gateway when configured. It only falls back
/// locally for explicitly eligible configuration/offline failures; auth,
/// validation, permission, and unknown programming errors are not swallowed.
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
        includePersonalContext: includePersonalContext,
      );
    } on AurenAiFallbackEligibleException {
      return fallback.send(
        conversationId: conversationId,
        message: message,
      );
    } on FirebaseFunctionsException catch (e) {
      // Only infrastructure failures may use the local fallback.
      // Authentication, permission, validation, and provider errors propagate.
      const transientCodes = {
        'unavailable',
        'deadline-exceeded',
        'internal',
        'unknown',
      };
      if (!transientCodes.contains(e.code)) rethrow;
      return fallback.send(
        conversationId: conversationId,
        message: message,
      );
    }
  }
}
