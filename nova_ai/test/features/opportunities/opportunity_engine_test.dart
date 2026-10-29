import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/opportunities/opportunity_engine.dart';
import 'package:nova_ai/features/opportunities/global_opportunity_radar_engine.dart';

void main() {
  group('OpportunityCandidate', () {
    test('scores stronger demand and evidence higher', () {
      const strong = OpportunityCandidate(
        name: 'A', evidence: 'survey', demand: 90, trend: 80,
        monetization: 85, evidenceStrength: 90, competition: 20, executionCost: 20,
      );
      const weak = OpportunityCandidate(
        name: 'B', evidence: 'guess', demand: 30, trend: 20,
        monetization: 30, evidenceStrength: 20, competition: 80, executionCost: 90,
      );
      expect(strong.score, greaterThan(weak.score));
      expect(strong.recommendation, 'اختبرها بتجربة صغيرة ومحددة');
    });

    test('rejects out-of-range scores', () {
      const invalid = OpportunityCandidate(
        name: 'bad', evidence: '', demand: 101, trend: 0,
        monetization: 0, evidenceStrength: 0, competition: 0, executionCost: 0,
      );
      expect(() => invalid.score, throwsArgumentError);
    });

    test('requires evidence before recommending investment', () {
      const candidate = OpportunityCandidate(
        name: 'unknown', evidence: '', demand: 100, trend: 100,
        monetization: 100, evidenceStrength: 10, competition: 0, executionCost: 0,
      );
      expect(candidate.recommendation, 'اجمع أدلة أكثر قبل الاستثمار');
    });

    test('ranks candidates best-first and returns immutable result', () {
      const a = OpportunityCandidate(name: 'A', evidence: '', demand: 80, trend: 80,
        monetization: 80, evidenceStrength: 80, competition: 20, executionCost: 20);
      const b = OpportunityCandidate(name: 'B', evidence: '', demand: 20, trend: 20,
        monetization: 20, evidenceStrength: 20, competition: 80, executionCost: 80);
      final ranked = rankOpportunities([b, a]);
      expect(ranked.first.name, 'A');
      expect(() => ranked.add(a), throwsUnsupportedError);
    });
  });

  group('Public opportunity listing URL validation', () {
    test('accepts HTTPS listings from the expected source domains', () {
      final remotive = parseRemotiveLead({'title': 'Remote role', 'url': 'https://remotive.com/remote-jobs/example'});
      final arbeitnow = parseArbeitnowLead({'title': 'Remote role', 'url': 'https://www.arbeitnow.com/jobs/example'});
      expect(remotive, isNotNull);
      expect(arbeitnow, isNotNull);
    });

    test('rejects deceptive hosts, HTTP, and URLs containing credentials', () {
      expect(parseRemotiveLead({'title': 'Fake', 'url': 'https://remotive.com.attacker.test/job'}), isNull);
      expect(parseRemotiveLead({'title': 'HTTP', 'url': 'http://remotive.com/job'}), isNull);
      expect(parseArbeitnowLead({'title': 'Fake', 'url': 'https://arbeitnow.com.attacker.test/job'}), isNull);
      expect(parseArbeitnowLead({'title': 'Credential URL', 'url': 'https://user:pass@arbeitnow.com/job'}), isNull);
    });
  });

  group('RevenueScenario', () {
    test('calculates gross revenue, profit and margin transparently', () {
      const scenario = RevenueScenario(expectedCustomers: 10, revenuePerCustomer: 25,
        directCosts: 80, otherCosts: 20);
      expect(scenario.grossRevenue, 250);
      expect(scenario.estimatedProfit, 150);
      expect(scenario.marginPercent, 60);
    });

    test('handles zero revenue and rejects negative inputs', () {
      const zero = RevenueScenario(expectedCustomers: 0, revenuePerCustomer: 10,
        directCosts: 0, otherCosts: 0);
      expect(zero.marginPercent, 0);
      const invalid = RevenueScenario(expectedCustomers: -1, revenuePerCustomer: 10,
        directCosts: 0, otherCosts: 0);
      expect(() => invalid.estimatedProfit, throwsArgumentError);
    });
  });
}
