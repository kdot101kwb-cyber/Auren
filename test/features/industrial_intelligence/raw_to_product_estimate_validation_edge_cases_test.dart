import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/industrial_intelligence/domain/raw_to_product_estimate.dart';

void main() {
  group('RawToProductEstimate input validation edge cases', () {
    const valid = <String, double>{
      'rawQuantity': 10,
      'yieldPercent': 80,
      'rawUnitCost': 2,
      'processingPerRawUnit': 1,
      'packagingPerProduct': 0.5,
      'transportCost': 1,
      'otherCosts': 0,
      'sellingPricePerProduct': 4,
    };

    RawToProductEstimate calculate(Map<String, double> values) {
      return RawToProductEstimate.calculate(
        rawQuantity: values['rawQuantity']!,
        yieldPercent: values['yieldPercent']!,
        rawUnitCost: values['rawUnitCost']!,
        processingPerRawUnit: values['processingPerRawUnit']!,
        packagingPerProduct: values['packagingPerProduct']!,
        transportCost: values['transportCost']!,
        otherCosts: values['otherCosts']!,
        sellingPricePerProduct: values['sellingPricePerProduct']!,
      );
    }

    for (final field in valid.keys) {
      test('rejects a negative $field', () {
        expect(
          () => calculate({...valid, field: -0.01}),
          throwsArgumentError,
        );
      });

      test('rejects NaN in $field', () {
        expect(
          () => calculate({...valid, field: double.nan}),
          throwsArgumentError,
        );
      });

      test('rejects positive infinity in $field', () {
        expect(
          () => calculate({...valid, field: double.infinity}),
          throwsArgumentError,
        );
      });

      test('rejects negative infinity in $field', () {
        expect(
          () => calculate({...valid, field: double.negativeInfinity}),
          throwsArgumentError,
        );
      });
    }

    test('accepts zero for every cost and price input', () {
      final result = calculate({
        ...valid,
        'rawUnitCost': 0,
        'processingPerRawUnit': 0,
        'packagingPerProduct': 0,
        'transportCost': 0,
        'otherCosts': 0,
        'sellingPricePerProduct': 0,
      });

      expect(result.outputQuantity, 8);
      expect(result.totalCost, 0);
      expect(result.revenue, 0);
      expect(result.profitOrLoss, 0);
      expect(result.unitCost, 0);
      expect(result.salesMarginPercent, isNull);
    });
  });
}
