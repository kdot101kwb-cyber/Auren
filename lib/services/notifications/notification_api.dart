import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AurenNotificationApi {
  static const _backendUrl = String.fromEnvironment('AUREN_BACKEND_URL');
  static const _aiGatewayUrl = String.fromEnvironment('AUREN_AI_GATEWAY_URL');

  String get _baseUrl {
    final configured = _backendUrl.trim().isNotEmpty ? _backendUrl.trim() : _aiGatewayUrl.trim();
    if (configured.isEmpty) return '';
    return configured.endsWith('/api/ai/chat')
        ? configured.substring(0, configured.length - '/api/ai/chat'.length)
        : configured.replaceFirst(RegExp(r'/$'), '');
  }

  Future<void> notifyMessage({
    required String conversationId,
    required String messageId,
    required String text,
  }) async {
    if (_baseUrl.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) return;

    final response = await http.post(
      Uri.parse('$_baseUrl/api/notifications/message'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'conversationId': conversationId,
        'messageId': messageId,
        'text': text,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Notification service returned ${response.statusCode}.');
    }
  }
  Future<void> notifyGroupChange({
    required String conversationId,
    required String type,
    String? targetUid,
  }) async {
    if (_baseUrl.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) return;

    final response = await http.post(
      Uri.parse('$_baseUrl/api/notifications/group'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'conversationId': conversationId,
        'type': type,
        if (targetUid != null) 'targetUid': targetUid,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Group notification service returned ${response.statusCode}.');
    }
  }

}
