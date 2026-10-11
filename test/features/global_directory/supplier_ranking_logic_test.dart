import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/global_directory/domain/supplier_ranking_logic.dart';

void main() {
  group('SupplierRankingCandidate.totalCost', () {
    test('adds valid price and shipping', () {
      const candidate = SupplierRankingCandidate(
        id: 'a', name: 'A', currency: 'USD', price: 100, shipping: 12.5,
      );
      expect(candidate.totalCost, 112.5);
    });

    test('rejects missing, negative, and non-finite cost components', () {
      expect(const SupplierRankingCandidate(
        id: 'a', name: 'A', currency: 'USD', price: 100,
      ).totalCost, isNull);
      expect(const SupplierRankingCandidate(
        id: 'a', name: 'A', currency: 'USD', price: -1, shipping: 0,
      ).totalCost, isNull);
      expect(const SupplierRankingCandidate(
        id: 'a', name: 'A', currency: 'USD', price: double.infinity, shipping: 0,
      ).totalCost, isNull);
    });
  });

  group('SupplierRankingLogic.rank', () {
    const candidates = [
      SupplierRankingCandidate(
        id: 'low', name: 'Low price', currency: 'USD',
        price: 80, shipping: 10, leadTimeDays: 5, minimumOrder: 10,
        verified: true, rating: 5,
      ),
      SupplierRankingCandidate(
        id: 'fast', name: 'Fast supplier', currency: 'USD',
        price: 95, shipping: 5, leadTimeDays: 2, minimumOrder: 5,
        verified: true, rating: 4,
      ),
      SupplierRankingCandidate(
        id: 'eur', name: 'Euro supplier', currency: 'EUR',
        price: 1, shipping: 0, leadTimeDays: 1, minimumOrder: 1,
        verified: true, rating: 5,
      ),
    ];

    test('ranks only within the requested currency and explains scores', () {
      final result = SupplierRankingLogic.rank(
        candidates, currency: 'usd', maxLeadTimeDays: 7,
        maxBudget: 100, maxMinimumOrder: 20,
      );
      expect(result, hasLength(2));
      expect(result.first.candidate.id, 'low');
      expect(result.first.score, greaterThan(result.last.score));
      expect(result.first.reasons, contains('lowest_comparable_total_cost'));
      expect(result.first.reasons, contains('marked_verified'));
    });

    test('does not treat missing data as a positive signal', () {
      const incomplete = SupplierRankingCandidate(
        id: 'unknown', name: 'Unknown', currency: 'USD',
      );
      final result = SupplierRankingLogic.rank(
        [incomplete], currency: 'USD', maxLeadTimeDays: 3,
        maxBudget: 100, maxMinimumOrder: 10,
      ).single;
      expect(result.score, 0);
      expect(result.warnings, contains('missing_or_invalid_cost'));
      expect(result.warnings, contains('missing_or_invalid_lead_time'));
      expect(result.warnings, contains('missing_or_invalid_minimum_order'));
      expect(result.warnings, contains('supplier_not_verified'));
      expect(result.warnings, contains('missing_or_invalid_rating'));
    });

    test('normalizes currency codes and returns immutable results', () {
      final result = SupplierRankingLogic.rank(
        candidates, currency: ' usd ',
      );
      expect(result, hasLength(2));
      expect(() => result.clear(), throwsUnsupportedError);
    });

    test('uses cost then name for deterministic ties', () {
      const tied = [
        SupplierRankingCandidate(
          id: 'z', name: 'Zulu', currency: 'USD',
          price: 10, shipping: 0, leadTimeDays: 1,
          minimumOrder: 1, verified: true, rating: 5,
        ),
        SupplierRankingCandidate(
          id: 'a', name: 'Alpha', currency: 'USD',
          price: 10, shipping: 0, leadTimeDays: 1,
          minimumOrder: 1, verified: true, rating: 5,
        ),
      ];
      final result = SupplierRankingLogic.rank(tied, currency: 'USD');
      expect(result.map((item) => item.candidate.id), ['a', 'z']);
    });

    test('returns no candidates for a currency without matching offers', () {
      expect(
        SupplierRankingLogic.rank(candidates, currency: 'GBP'),
        isEmpty,
      );
    });
  });
}
