import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/business_economy/domain/business_economy_logic.dart';

void main() {
  group('AurenBusinessEconomyLogic.scoreMatch', () {
    test('returns zero when no comparable input is supplied', () {
      final result = AurenBusinessEconomyLogic.scoreMatch(
        const AurenBusinessMatchInput(buyerNeed: '', sellerOffer: ''),
      );
      expect(result.score, 0);
      expect(result.reasons, isEmpty);
    });

    test('scores shared terms, category and location without exceeding 100', () {
      final result = AurenBusinessEconomyLogic.scoreMatch(
        const AurenBusinessMatchInput(
          buyerNeed: 'organic sesame bags',
          sellerOffer: 'organic sesame available',
          buyerCategory: 'Agriculture',
          sellerCategory: 'agriculture',
          buyerLocation: 'Khartoum',
          sellerLocation: 'khartoum',
        ),
      );
      expect(result.score, inInclusiveRange(40, 100));
      expect(result.score, lessThanOrEqualTo(100));
      expect(result.reasons, hasLength(3));
    });

    test('does not award category or location points for blank values', () {
      final result = AurenBusinessEconomyLogic.scoreMatch(
        const AurenBusinessMatchInput(
          buyerNeed: 'cotton',
          sellerOffer: 'cotton',
          buyerCategory: '',
          sellerCategory: '',
          buyerLocation: '',
          sellerLocation: '',
        ),
      );
      expect(result.score, 60);
      expect(result.reasons, hasLength(1));
    });
  });

  group('AurenBusinessEconomyLogic.buildGrowthSteps', () {
    test('trims and omits empty fields', () {
      expect(
        AurenBusinessEconomyLogic.buildGrowthSteps(
          goal: '  Get 10 customers ',
          customerGroup: '',
          nextAction: ' Call three shops ',
        ),
        ['Goal: Get 10 customers', 'Next action: Call three shops'],
      );
    });

    test('returns no steps when all fields are empty', () {
      expect(
        AurenBusinessEconomyLogic.buildGrowthSteps(
          goal: ' ',
          customerGroup: '',
          nextAction: '',
        ),
        isEmpty,
      );
    });
  });
}
