import 'dart:convert';

import 'package:auren/features/culture/presentation/auren_live_news_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('live news displays source links and a verification disclaimer',
      (tester) async {
    final client = MockClient((request) async {
      expect(request.url.host, 'api.gdeltproject.org');
      expect(request.url.queryParameters['mode'], 'ArtList');
      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'articles': [
            {
              'title': 'Sudan regional update',
              'url': 'https://example.org/news',
              'domain': 'example.org',
              'seendate': '20261020T120000Z',
            }
          ],
        })),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    await tester.pumpWidget(
      MaterialApp(home: AurenLiveNewsScreen(client: client)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sudan regional update'), findsOneWidget);
    expect(find.textContaining('example.org'), findsOneWidget);
    expect(find.textContaining('لا يعني أن AUREN تحقّق من صحته'), findsOneWidget);
    expect(find.text('Sudan & Africa'), findsOneWidget);
  });

  testWidgets('live news offers a retry state when the service fails',
      (tester) async {
    final client = MockClient((_) async => http.Response('unavailable', 503));

    await tester.pumpWidget(
      MaterialApp(home: AurenLiveNewsScreen(client: client)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('تعذّر تحميل الأخبار الآن'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('live news handles an empty result list', (tester) async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'articles': []}),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: AurenLiveNewsScreen(client: client)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('لا توجد نتائج لهذا القسم حالياً'), findsOneWidget);
  });
}
