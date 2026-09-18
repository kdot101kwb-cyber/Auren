import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/models/ai_response.dart';
import 'ai_gateway.dart';

class HttpsAurenAiGateway implements AurenAiGateway {
  static const String endpoint = String.fromEnvironment('AUREN_AI_GATEWAY_URL');

  const HttpsAurenAiGateway();

  @override
  Future<AurenAiResponse> send({
    required String conversationId,
    required String message,
  }) async {
    if (endpoint.isEmpty) {
      throw StateError('AUREN_AI_GATEWAY_URL is not configured.');
    }

    final response = await http.post(
      Uri.parse(endpoint),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'conversationId': conversationId,
        'message': message,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('AUREN AI gateway returned ${response.statusCode}.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AurenAiResponse(
      text: data['text'] as String? ?? '',
      action: data['action'] as String?,
      requiresApproval: data['requiresApproval'] as bool? ?? false,
    );
  }
}
