import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

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

class HttpsAurenActionExecutor implements AurenActionExecutor {
  static const String endpoint =
      String.fromEnvironment('AUREN_ACTION_EXECUTOR_URL');

  final FirebaseAuth _auth;

  HttpsAurenActionExecutor({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<AurenActionExecutionResult> execute({
    required String uid,
    required AurenActionRequest action,
  }) async {
    if (endpoint.isEmpty) {
      throw StateError('AUREN_ACTION_EXECUTOR_URL is not configured.');
    }

    final user = _auth.currentUser;
    if (user == null || user.uid != uid) {
      throw StateError(
        'Authenticated user is missing or does not match action owner.',
      );
    }

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not obtain Firebase authentication token.');
    }

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'actionId': action.id,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'AUREN action executor returned ${response.statusCode}.',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AurenActionExecutionResult(
      result: data['result'] as String? ?? 'Action completed.',
      status: data['status'] as String? ?? 'completed',
    );
  }
}
