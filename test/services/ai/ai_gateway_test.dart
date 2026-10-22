import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/core/models/ai_response.dart';
import 'package:auren/services/ai/ai_gateway.dart';

void main() {
  test('does not hide authentication or programming StateErrors', () async {
    final remote = _FakeGateway(
      error: StateError('AUREN account is not authenticated.'),
    );
    final fallback = _FakeGateway();
    final gateway = ResilientAurenAiGateway(
      remote: remote,
      fallback: fallback,
    );

    await expectLater(
      gateway.send(conversationId: 'conversation-1', message: 'private text'),
      throwsA(isA<StateError>()),
    );
    expect(remote.calls, 1);
    expect(fallback.calls, 0);
  });

  test('uses local fallback for explicit missing-configuration failures',
      () async {
    final remote = _FakeGateway(
      error: const AurenAiFallbackEligibleException('endpoint not configured'),
    );
    final fallback = _FakeGateway(response: const AurenAiResponse(text: 'local'));
    final gateway = ResilientAurenAiGateway(
      remote: remote,
      fallback: fallback,
    );

    final response = await gateway.send(
      conversationId: 'conversation-1',
      message: 'hello',
    );

    expect(response.text, 'local');
    expect(fallback.calls, 1);
  });

  test('does not use local fallback for permission failures', () async {
    final remote = _FakeGateway(
      error: FirebaseFunctionsException(
        code: 'permission-denied',
        message: 'not allowed',
      ),
    );
    final fallback = _FakeGateway();
    final gateway = ResilientAurenAiGateway(
      remote: remote,
      fallback: fallback,
    );

    await expectLater(
      gateway.send(conversationId: 'conversation-1', message: 'hello'),
      throwsA(isA<FirebaseFunctionsException>()),
    );
    expect(fallback.calls, 0);
  });
}

class _FakeGateway implements AurenAiGateway {
  _FakeGateway({this.error, this.response = const AurenAiResponse(text: 'remote')});

  final Object? error;
  final AurenAiResponse response;
  int calls = 0;

  @override
  Future<AurenAiResponse> send({
    required String conversationId,
    required String message,
    String? requestId,
    bool includePersonalContext = false,
  }) async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return response;
  }
}
