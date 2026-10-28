import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nova_ai/features/engineering/nova_repository_inspector.dart';

void main() {
  test('fetches and decodes a source file from the pinned repository and ref', () async {
    Uri? requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response(jsonEncode({
        'type': 'file',
        'encoding': 'base64',
        'sha': 'abc123',
        'content': base64.encode(utf8.encode('class Example {}\n')),
      }), 200);
    });
    final inspector = NovaRepositoryInspector(client: client);

    final result = await inspector.inspect('nova_ai/lib/example.dart');

    expect(requested!.host, 'api.github.com');
    expect(requested!.path, '/repos/kdot101kwb-cyber/Auren/contents/nova_ai/lib/example.dart');
    expect(requested!.queryParameters['ref'], NovaRepositoryInspector.defaultRef);
    expect(result.content, 'class Example {}\n');
    expect(result.sha, 'abc123');
    client.close();
  });

  test('rejects path traversal and paths outside source/test folders before network access', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('{}', 200);
    });
    final inspector = NovaRepositoryInspector(client: client);

    await expectLater(inspector.inspect('../README.md'), throwsArgumentError);
    await expectLater(inspector.inspect('nova_ai/../../README.md'), throwsArgumentError);
    await expectLater(inspector.inspect('.github/workflows/ci.yml'), throwsArgumentError);
    expect(requests, 0);
    client.close();
  });

  test('rejects non-file responses', () async {
    final client = MockClient((_) async => http.Response(jsonEncode({'type': 'dir'}), 200));
    final inspector = NovaRepositoryInspector(client: client);
    await expectLater(
      inspector.inspect('nova_ai/lib/example.dart'),
      throwsA(isA<NovaRepositoryInspectionException>()),
    );
    client.close();
  });

  test('handles a missing public file clearly', () async {
    final client = MockClient((_) async => http.Response('{}', 404));
    final inspector = NovaRepositoryInspector(client: client);
    await expectLater(
      inspector.inspect('nova_ai/lib/missing.dart'),
      throwsA(isA<NovaRepositoryInspectionException>()),
    );
    client.close();
  });
}
