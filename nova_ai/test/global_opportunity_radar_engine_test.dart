import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/opportunities/global_opportunity_radar_engine.dart';

void main() {
  group('global opportunity radar engine', () {
    test('does not treat missing location as worldwide or Sudan-eligible', () {
      expect(
        classifySudanEligibility('Eligibility not stated'),
        RadarSudanEligibility.locationNotStated,
      );
      expect(
        classifySudanEligibility('Country not stated'),
        RadarSudanEligibility.locationNotStated,
      );
      expect(
        classifySudanEligibility('Worldwide'),
        RadarSudanEligibility.worldwideNeedsConfirmation,
      );
      expect(
        classifySudanEligibility('Sudan'),
        RadarSudanEligibility.explicitlyListsSudan,
      );
    });

    test('Sudan filter excludes unknown locations but retains worldwide for manual verification', () {
      GlobalOpportunityLead lead(String id, String country) => GlobalOpportunityLead(
        id: id, title: 'Remote data work', description: '', company: '',
        country: country, category: 'AI & Data', source: 'Test',
        url: 'https://example.com/$id', language: 'English', salary: '',
        remote: true,
      );
      final results = rankGlobalLeads(
        [lead('unknown', 'Eligibility not stated'), lead('world', 'Worldwide'), lead('sd', 'Sudan')],
        country: 'Sudan',
      );
      expect(results.map((item) => item.id), containsAll(['world', 'sd']));
      expect(results.map((item) => item.id), isNot(contains('unknown')));
      expect(classifySudanEligibility(results.firstWhere((item) => item.id == 'world').country),
          RadarSudanEligibility.worldwideNeedsConfirmation);
    });

    test('Remotive missing location is stored as unknown rather than worldwide', () {
      final lead = parseRemotiveLead({
        'title': 'Remote assistant',
        'url': 'https://example.com/assistant',
      });
      expect(lead, isNotNull);
      expect(lead!.country, 'Eligibility not stated');
      expect(classifySudanEligibility(lead.country), RadarSudanEligibility.locationNotStated);
    });
    test('deduplicates repeated records by source id or exact source URL', () {
      GlobalOpportunityLead lead(String id, String url) => GlobalOpportunityLead(
        id: id, title: 'Remote translator', description: 'Arabic work',
        company: 'Example', country: 'Worldwide', category: 'Translation',
        source: 'Test', url: url, language: 'Arabic', salary: '', remote: true,
      );
      final results = rankGlobalLeads([
        lead('same-id', 'https://example.com/jobs/1'),
        lead('same-id', 'https://example.com/jobs/1?tracking=1'),
        lead('other-id', 'https://example.com/jobs/1'),
      ]);
      expect(results, hasLength(1));
      expect(results.single.id, 'same-id');
    });

    test('expands categories into multiple language query terms', () {
      final queries = expandRadarQueries('', category: 'Translation');
      expect(queries, contains('ترجمة'));
      expect(queries, contains('translation'));
      expect(queries.length, greaterThan(3));
    });

    test('preserves a user query and adds category terms', () {
      final queries = expandRadarQueries('Swahili audio', category: 'AI & Data');
      expect(queries.first, 'Swahili audio');
      expect(queries, contains('AI evaluation'));
    });

    test('parses Remotive records and strips markup', () {
      final lead = parseRemotiveLead({
        'id': 22,
        'title': 'Arabic Transcriber',
        'url': 'https://example.com/job/22',
        'description': '<p>Review &amp; transcribe Arabic audio</p>',
        'company_name': 'Example Co',
        'candidate_required_location': 'Worldwide',
        'publication_date': '2026-10-20T00:00:00',
        'salary': 'USD 15/hour',
      });
      expect(lead, isNotNull);
      expect(lead!.title, 'Arabic Transcriber');
      expect(lead.description, contains('Review & transcribe'));
      expect(lead.remote, isTrue);
      expect(lead.salary, 'USD 15/hour');
    });

    test('rejects unsafe or missing listing URLs', () {
      expect(parseRemotiveLead({'title': 'Bad', 'url': 'javascript:alert(1)'}), isNull);
      expect(parseArbeitnowLead({'title': 'No URL'}), isNull);
    });

    test('ranks remote listings with direct source links above incomplete rows', () {
      final incomplete = GlobalOpportunityLead(
        id: 'b', title: 'Translator', description: '', company: '',
        country: 'Country not stated', category: '', source: 'Test',
        url: '', language: '', salary: '', remote: false,
      );
      final verifiedLink = GlobalOpportunityLead(
        id: 'a', title: 'Remote Translator', description: 'Arabic translation',
        company: 'Company', country: 'Worldwide', category: 'Translation',
        source: 'Test', url: 'https://example.com/job', language: 'Arabic',
        salary: 'Pay listed', remote: true, publishedAt: DateTime.now(),
      );
      final result = rankGlobalLeads([incomplete, verifiedLink], query: 'translation');
      expect(result.map((e) => e.id), ['a']);
    });

    test('round trips saved opportunities', () {
      final lead = GlobalOpportunityLead(
        id: 'saved-1', title: 'Arabic QA', description: 'Check transcripts',
        company: 'Example', country: 'Sudan', category: 'AI & Data',
        source: 'Test', url: 'https://example.com', language: 'Arabic',
        salary: '', remote: true,
      );
      final decoded = decodeSavedRadarLeads(jsonEncode([lead.toJson()]));
      expect(decoded.single.id, lead.id);
      expect(decoded.single.country, 'Sudan');
    });
  });
}
