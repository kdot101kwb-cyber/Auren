import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
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
    if (endpoint.isEmpty) throw StateError('AUREN_AI_GATEWAY_URL is not configured.');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('AUREN account is not authenticated.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw StateError('AUREN authentication token is unavailable.');

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'content-type': 'application/json', 'authorization': 'Bearer $token'},
      body: jsonEncode({'conversationId': conversationId, 'message': message}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('AUREN AI gateway returned ${response.statusCode}.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawPayload = data['payload'];
    return AurenAiResponse(
      text: data['text'] as String? ?? '',
      action: data['action'] as String?,
      payload: rawPayload is Map ? Map<String, dynamic>.from(rawPayload) : const {},
      requiresApproval: data['requiresApproval'] as bool? ?? false,
    );
  }
}
