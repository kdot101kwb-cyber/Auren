import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/opportunities/global_opportunity_radar_engine.dart';

void main() {
  group('global opportunity radar engine', () {
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

    test('flags advance-fee and wallet credential requests as high risk', () {
      final lead = GlobalOpportunityLead(
        id: 'fee', title: 'Remote assistant',
        description: 'Pay a registration fee before starting and send your wallet seed phrase.',
        company: 'Unknown', country: 'Worldwide', category: 'Work',
        source: 'Test', url: 'https://example.com/job', language: '',
        salary: '', remote: true,
      );
      final assessment = assessOpportunitySafety(lead);
      expect(assessment.level, OpportunityRiskLevel.high);
      expect(assessment.hasWarnings, isTrue);
    });

    test('flags guaranteed income claims for manual review', () {
      final lead = GlobalOpportunityLead(
        id: 'promise', title: 'Guaranteed income', description: 'Risk-free profit every day',
        company: 'Unknown', country: 'Worldwide', category: 'Work',
        source: 'Test', url: 'https://example.com/job', language: '',
        salary: '', remote: true,
      );
      expect(assessOpportunitySafety(lead).level, OpportunityRiskLevel.review);
    });

    test('does not label ordinary paid work as suspicious by default', () {
      final lead = GlobalOpportunityLead(
        id: 'normal', title: 'Arabic translator', description: 'Translate documents for clients.',
        company: 'Example', country: 'Sudan', category: 'Translation',
        source: 'Test', url: 'https://example.com/job', language: 'Arabic',
        salary: 'USD 10 per task', remote: true,
      );
      expect(assessOpportunitySafety(lead).level, OpportunityRiskLevel.low);
      expect(assessOpportunitySafety(lead).hasWarnings, isFalse);
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
