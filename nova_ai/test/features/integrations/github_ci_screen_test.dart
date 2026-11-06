import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nova_ai/features/integrations/github_ci_screen.dart';

void main() {
  final runs = {
    'workflow_runs': [
      {
        'display_title': 'Android build passed',
        'name': 'NOVA Android Build',
        'status': 'completed',
        'conclusion': 'success',
        'head_branch': 'feat/nova',
        'head_sha': '1234567890abcdef',
        'html_url': 'https://github.com/kdot101kwb-cyber/Auren/actions/runs/1',
        'created_at': '2026-11-06T18:00:00Z',
        'run_number': 10,
      },
      {
        'display_title': 'Functions tests failed',
        'name': 'Functions CI',
        'status': 'completed',
        'conclusion': 'failure',
        'head_branch': 'feat/nova',
        'head_sha': 'abcdef1234567890',
        'html_url': 'https://github.com/kdot101kwb-cyber/Auren/actions/runs/2',
        'created_at': '2026-11-06T17:00:00Z',
        'run_number': 9,
      },
      {
        'display_title': 'Security scan running',
        'name': 'Security',
        'status': 'in_progress',
        'conclusion': null,
        'head_branch': 'feat/nova',
        'head_sha': 'fedcba0987654321',
        'html_url': 'https://github.com/kdot101kwb-cyber/Auren/actions/runs/3',
        'created_at': '2026-11-06T16:00:00Z',
        'run_number': 8,
      },
    ],
  };

  testWidgets('shows health totals and filters workflow runs', (tester) async {
    final client = MockClient((request) async {
      expect(request.url.path, '/repos/kdot101kwb-cyber/Auren/actions/runs');
      return http.Response(jsonEncode(runs), 200);
    });
    addTearDown(client.close);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: GitHubCiScreen(httpClient: client))));
    await tester.pumpAndSettle();

    expect(find.text('النجاح'), findsOneWidget);
    expect(find.text('الفشل'), findsOneWidget);
    expect(find.text('الجارية'), findsOneWidget);
    expect(find.text('Android build passed'), findsOneWidget);
    expect(find.text('Functions tests failed'), findsOneWidget);

    // Use the running filter to bring the third run into the rendered list.
    // This avoids relying on viewport dimensions or scroll physics in CI.
    await tester.tap(find.widgetWithText(ChoiceChip, 'قيد التنفيذ'));
    await tester.pumpAndSettle();
    expect(find.text('Security scan running'), findsOneWidget);
    expect(find.text('Android build passed'), findsNothing);
    expect(find.text('Functions tests failed'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'الفاشلة'));
    await tester.pumpAndSettle();
    expect(find.text('Functions tests failed'), findsOneWidget);
    expect(find.text('Android build passed'), findsNothing);
    expect(find.text('Security scan running'), findsNothing);
  });

  testWidgets('shows a clear empty-filter message when no run matches', (tester) async {
    final client = MockClient((request) async => http.Response(
          jsonEncode({
            'workflow_runs': [
              {
                'display_title': 'Only successful run',
                'name': 'Build',
                'status': 'completed',
                'conclusion': 'success',
                'head_branch': 'main',
                'head_sha': '1234567',
                'html_url': 'https://github.com/kdot101kwb-cyber/Auren/actions/runs/1',
                'created_at': '2026-11-06T18:00:00Z',
                'run_number': 1,
              },
            ],
          }),
          200,
        ));
    addTearDown(client.close);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: GitHubCiScreen(httpClient: client))));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'الفاشلة'));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد تشغيلات ضمن هذا التصنيف.'), findsOneWidget);
  });

  testWidgets('shows a retryable message when GitHub denies access', (tester) async {
    final client = MockClient((request) async => http.Response('{}', 403));
    addTearDown(client.close);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: GitHubCiScreen(httpClient: client))));
    await tester.pumpAndSettle();

    expect(find.text('لم يكتمل الاتصال'), findsOneWidget);
    expect(find.textContaining('تعذر الوصول إلى GitHub Actions'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
