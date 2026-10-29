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

    test('parses Himalayas listings with attribution, restrictions and salary', () {
      final lead = parseHimalayasLead({
        'guid': 'job-77',
        'title': 'Arabic Content Reviewer',
        'applicationLink': 'https://himalayas.app/jobs/example',
        'description': '<p>Review Arabic content</p>',
        'companyName': 'Example Company',
        'locationRestrictions': <String>[],
        'categories': <String>['Content', 'AI'],
        'employmentType': 'Contract',
        'minSalary': 15,
        'maxSalary': 20,
        'currency': 'USD',
        'salaryPeriod': 'hourly',
        'pubDate': 1792800000,
      });
      expect(lead, isNotNull);
      expect(lead!.url, 'https://himalayas.app/jobs/example');
      expect(lead.source, contains('himalayas.app'));
      expect(lead.country, contains('Worldwide'));
      expect(lead.salary, contains('USD 15–20 / hourly'));
      expect(lead.description, contains('Review Arabic content'));
    });

    test('rejects Himalayas application links that are not HTTPS', () {
      expect(parseHimalayasLead({
        'title': 'Unsafe listing',
        'applicationLink': 'javascript:alert(1)',
      }), isNull);
    });

    test('parses Jobicy public listings and keeps the canonical source URL', () {
      final lead = parseJobicyLead({
        'id': 501,
        'jobTitle': 'Remote Arabic Content Reviewer',
        'url': 'https://jobicy.com/jobs/example-role',
        'jobDescription': '<p>Review Arabic content</p>',
        'companyName': 'Example Studio',
        'jobGeo': 'Anywhere',
        'jobIndustry': 'Content',
        'jobType': 'Contract',
        'salaryMin': 20,
        'salaryMax': 30,
        'salaryCurrency': 'USD',
        'salaryPeriod': 'hourly',
        'pubDate': '2026-10-25T10:00:00Z',
      });
      expect(lead, isNotNull);
      expect(lead!.source, 'Jobicy');
      expect(lead.url, 'https://jobicy.com/jobs/example-role');
      expect(lead.country, 'Anywhere');
      expect(lead.salary, 'USD 20–30 / hourly');
      expect(lead.description, contains('Review Arabic content'));
    });

    test('rejects unsafe Jobicy listing URLs', () {
      expect(parseJobicyLead({
        'jobTitle': 'Unsafe role',
        'url': 'javascript:alert(1)',
      }), isNull);
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

    test('prepares an editable content proposal and Sudan/payment checks', () {
      final lead = GlobalOpportunityLead(
        id: 'content-1', title: 'Social Media Content Writer',
        description: 'Write short social media posts and scripts',
        company: 'Example Studio', country: 'Worldwide', category: 'Content',
        source: 'Test', url: 'https://example.com/job', language: 'English',
        salary: '', remote: true,
      );
      final pack = prepareOpportunityWorkPack(lead);
      expect(pack.proposalDraft, contains('Example Studio'));
      expect(pack.sampleTask, contains('الموضوع'));
      expect(pack.sampleTask, contains('موجز العميل'));
      expect(pack.preparationPlan, contains('مسودة'));
      expect(pack.checksBeforeApplying.any((item) => item.contains('السودان')), isTrue);
      expect(pack.checksBeforeApplying.any((item) => item.contains('رسوماً')), isTrue);
      expect(pack.toPlainText(), contains('ملف تحضير فرصة'));
    });

    test('prepares data work sample without implying customer data access', () {
      final lead = GlobalOpportunityLead(
        id: 'data-1', title: 'AI Data Annotation',
        description: 'Label and categorize data for AI evaluation',
        company: '', country: 'Location not stated', category: 'AI & Data',
        source: 'Test', url: 'https://example.com/job', language: '',
        salary: '', remote: true,
      );
      final pack = prepareOpportunityWorkPack(lead);
      expect(pack.sampleTask, contains('بيانات اصطناعية'));
      expect(pack.checksBeforeApplying.any((item) => item.contains('السودان')), isTrue);
    });

    test('suggests practical NOVA assistance without claiming autonomous completion', () {
      final lead = GlobalOpportunityLead(
        id: 'ai-content-1', title: 'Arabic Social Media Content Writer',
        description: 'Create social media content and short video scripts',
        company: 'Example', country: 'Worldwide', category: 'Content',
        source: 'Test', url: 'https://example.com/job', language: 'Arabic',
        salary: '', remote: true,
      );
      final plan = novaExecutionPlanForLead(lead);
      expect(plan.any((step) => step.contains('مسودة محتوى')), isTrue);
      expect(plan.any((step) => step.contains('ليست تلقائية')), isTrue);
    });

    test('flags unknown Sudan eligibility, missing pay, and payout method', () {
      final lead = GlobalOpportunityLead(
        id: 'check-1', title: 'Remote assistant', description: '',
        company: 'Example', country: 'Worldwide', category: 'Work',
        source: 'Test', url: 'https://example.com/job', language: '',
        salary: '', remote: true,
      );
      final warnings = opportunityVerificationWarnings(lead);
      expect(warnings.any((warning) => warning.contains('السودان')), isTrue);
      expect(warnings.any((warning) => warning.contains('الأجر')), isTrue);
      expect(warnings.any((warning) => warning.contains('وسيلة الدفع')), isTrue);
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
