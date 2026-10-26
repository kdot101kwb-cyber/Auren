import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nova_ai/features/integrations/auren_repository_browser_screen.dart';

void main() {
  testWidgets('loads and filters AUREN repository files', (tester) async {
    final client = MockClient((request) async {
      expect(request.url.host, 'api.github.com');
      expect(request.url.path, contains('/git/trees/'));
      return http.Response(
        jsonEncode({
          'tree': [
            {'type': 'blob', 'path': 'nova_ai/lib/main.dart', 'size': 120},
            {'type': 'blob', 'path': 'README.md', 'size': 20},
            {'type': 'tree', 'path': 'nova_ai/lib', 'size': 0},
          ],
        }),
        200,
      );
    });
    addTearDown(client.close);

    await tester.pumpWidget(MaterialApp(
      home: AurenRepositoryBrowserScreen(client: client),
    ));
    await tester.pumpAndSettle();

    expect(find.text('nova_ai/lib/main.dart'), findsOneWidget);
    expect(find.text('README.md'), findsOneWidget);
    expect(find.text('nova_ai/lib'), findsNothing);

    await tester.enterText(find.byType(TextField), 'main.dart');
    await tester.pumpAndSettle();
    expect(find.text('nova_ai/lib/main.dart'), findsOneWidget);
    expect(find.text('README.md'), findsNothing);
  });

  testWidgets('decodes base64 file content returned by GitHub', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path.contains('/git/trees/')) {
        return http.Response(
          jsonEncode({
            'tree': [
              {'type': 'blob', 'path': 'README.md', 'size': 16},
            ],
          }),
          200,
        );
      }
      expect(request.url.path, contains('/contents/README.md'));
      // GitHub content responses may contain whitespace/newlines in base64.
      return http.Response(
        jsonEncode({'content': 'aGVs\nbG8gZnJvbSBBVVJFTg==', 'encoding': 'base64'}),
        200,
      );
    });
    addTearDown(client.close);

    await tester.pumpWidget(MaterialApp(
      home: AurenRepositoryBrowserScreen(client: client),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('README.md'));
    await tester.pumpAndSettle();

    expect(find.text('hello from AUREN'), findsOneWidget);
    expect(find.text('README.md'), findsOneWidget);
  });

  testWidgets('shows a readable error when GitHub is unavailable', (tester) async {
    final client = MockClient((request) async => http.Response('unavailable', 503));
    addTearDown(client.close);

    await tester.pumpWidget(MaterialApp(
      home: AurenRepositoryBrowserScreen(client: client),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('تعذر تحميل ملفات AUREN'), findsOneWidget);
  });
}
