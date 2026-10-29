import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nova_ai/features/research/public_opportunity_research_connector.dart';
import 'package:nova_ai/features/research/research_connector.dart';

void main() {
  group('PublicOpportunityResearchConnector', () {
    test('combines valid listings from both public sources', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'remotive.com') {
          expect(request.url.queryParameters['search'], 'flutter developer');
          return http.Response(
            jsonEncode({
              'jobs': [
                {
                  'title': 'Flutter Engineer',
                  'url': 'https://remotive.com/remote-jobs/example',
                  'description': '<p>Build mobile apps &amp; tools</p>',
                  'publication_date': '2026-10-20T00:00:00Z',
                },
                {
                  'title': 'Unsafe',
                  'url': 'http://evil.example/job',
                },
              ],
            }),
            200,
          );
        }
        expect(request.url.host, 'www.arbeitnow.com');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'title': 'Flutter Developer',
                'url': 'https://www.arbeitnow.com/jobs/flutter-dev',
                'description': 'Flutter developer wanted',
                'company_name': 'Example Ltd',
                'location': 'Remote',
                'tags': ['flutter', 'mobile'],
                'created_at': '2026-10-21T00:00:00Z',
              },
            ],
          }),
          200,
        );
      });

      final connector = PublicOpportunityResearchConnector(client: client);
      final results = await connector.search(
        const ResearchQuery(text: 'flutter developer', maxResults: 10),
      );

      expect(results, hasLength(2));
      expect(results.map((result) => result.sourceId),
          containsAll(['remotive', 'arbeitnow']));
      expect(results.every((result) => result.isUsable), isTrue);
      expect(results.first.snippet, contains('Build mobile apps & tools'));
    });

    test('reports unavailable only when both sources fail', () async {
      final client = MockClient((request) async => http.Response('unavailable', 503));
      final connector = PublicOpportunityResearchConnector(client: client);

      await expectLater(
        connector.search(const ResearchQuery(text: 'remote jobs')),
        throwsA(isA<ResearchSourceUnavailableException>()),
      );
    });

    test('treats a healthy empty response as success', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'remotive.com') {
          return http.Response(jsonEncode({'jobs': []}), 200);
        }
        return http.Response('unavailable', 503);
      });
      final connector = PublicOpportunityResearchConnector(client: client);

      expect(
        await connector.search(const ResearchQuery(text: 'rare role')),
        isEmpty,
      );
    });

    test('rejects oversized response bodies', () async {
      final client = MockClient((request) async =>
          http.Response(jsonEncode({'jobs': []}), 200));
      final connector = PublicOpportunityResearchConnector(
        client: client,
        maxResponseBytes: 2,
      );

      await expectLater(
        connector.search(const ResearchQuery(text: 'jobs')),
        throwsA(isA<ResearchSourceUnavailableException>()),
      );
    });
  });
}
