import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/global_directory/domain/supplier_ranking_logic.dart';

void main() {
  group('SupplierRankingLogic currency safety', () {
    const candidates = [
      SupplierRankingCandidate(
        id: 'missing-currency',
        name: 'Unspecified currency',
        currency: '',
        price: 10,
        shipping: 0,
        leadTimeDays: 1,
        minimumOrder: 1,
      ),
      SupplierRankingCandidate(
        id: 'usd',
        name: 'US dollar supplier',
        currency: 'USD',
        price: 10,
        shipping: 0,
        leadTimeDays: 1,
        minimumOrder: 1,
      ),
    ];

    test('does not rank offers when requested currency is empty', () {
      expect(SupplierRankingLogic.rank(candidates, currency: ''), isEmpty);
    });

    test('does not treat whitespace currency as a comparable unit', () {
      expect(SupplierRankingLogic.rank(candidates, currency: '   '), isEmpty);
    });

    test('still ranks offers when a real currency is selected', () {
      final results = SupplierRankingLogic.rank(candidates, currency: 'usd');
      expect(results, hasLength(1));
      expect(results.single.candidate.id, 'usd');
    });
  });
}
