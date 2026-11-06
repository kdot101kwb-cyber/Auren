import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/opportunities/global_opportunity_radar_engine.dart';

GlobalOpportunityLead lead(String country) => GlobalOpportunityLead(
  id: country,
  title: 'Remote assistant',
  description: 'Remote support role',
  company: 'Example',
  country: country,
  category: 'Work',
  source: 'Test',
  url: 'https://example.com/job',
  language: 'English',
  salary: '',
  remote: true,
);

void main() {
  group('Sudan eligibility filtering', () {
    test('does not treat unstated eligibility as worldwide', () {
      final results = rankGlobalLeads(
        [lead('Worldwide eligibility not stated')],
        country: 'Sudan',
      );
      expect(results, isEmpty);
    });

    test('includes an explicitly worldwide listing for Sudan review', () {
      final results = rankGlobalLeads(
        [lead('Worldwide')],
        country: 'Sudan',
      );
      expect(results, hasLength(1));
    });

    test('includes a listing explicitly naming Sudan', () {
      final results = rankGlobalLeads(
        [lead('Sudan')],
        country: 'Sudan',
      );
      expect(results, hasLength(1));
    });

    test('removes duplicate listings returned by multiple searches', () {
      final first = lead('Worldwide');
      final duplicate = GlobalOpportunityLead(
        id: 'duplicate-provider-id',
        title: 'Same role from another query',
        description: 'Duplicate',
        company: 'Example',
        country: 'Worldwide',
        category: 'Work',
        source: 'Other source',
        url: 'https://example.com/job/',
        language: 'English',
        salary: '',
        remote: true,
      );
      final results = rankGlobalLeads([first, duplicate]);
      expect(results, hasLength(1));
      expect(results.single.id, first.id);
    });

    test('does not classify unstated eligibility as an Africa-wide listing', () {
      final results = rankGlobalLeads(
        [lead('Worldwide eligibility not stated')],
        region: 'Africa',
      );
      expect(results, isEmpty);
    });
  });
}
