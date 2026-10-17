import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/industrial_intelligence/domain/raw_to_product_estimate.dart';

void main() {
  group('RawToProductEstimate derived-value overflow', () {
    RawToProductEstimate calculate({
      double rawQuantity = 1,
      double yieldPercent = 100,
      double rawUnitCost = 0,
      double processingPerRawUnit = 0,
      double packagingPerProduct = 0,
      double transportCost = 0,
      double otherCosts = 0,
      double sellingPricePerProduct = 0,
    }) {
      return RawToProductEstimate.calculate(
        rawQuantity: rawQuantity,
        yieldPercent: yieldPercent,
        rawUnitCost: rawUnitCost,
        processingPerRawUnit: processingPerRawUnit,
        packagingPerProduct: packagingPerProduct,
        transportCost: transportCost,
        otherCosts: otherCosts,
        sellingPricePerProduct: sellingPricePerProduct,
      );
    }

    test('rejects overflow when adding raw and processing unit costs', () {
      expect(
        () => calculate(
          rawQuantity: 2,
          rawUnitCost: double.maxFinite,
          processingPerRawUnit: double.maxFinite,
        ),
        throwsArgumentError,
      );
    });

    test('rejects overflow when multiplying raw quantity by unit cost', () {
      expect(
        () => calculate(rawQuantity: 2, rawUnitCost: double.maxFinite),
        throwsArgumentError,
      );
    });

    test('rejects overflow when multiplying output by packaging cost', () {
      expect(
        () => calculate(
          rawQuantity: 2,
          yieldPercent: 100,
          packagingPerProduct: double.maxFinite,
        ),
        throwsArgumentError,
      );
    });

    test('rejects overflow when calculating revenue', () {
      expect(
        () => calculate(
          rawQuantity: 2,
          yieldPercent: 100,
          sellingPricePerProduct: double.maxFinite,
        ),
        throwsArgumentError,
      );
    });

    test('rejects overflow when total costs exceed finite range', () {
      expect(
        () => calculate(
          rawQuantity: 1,
          rawUnitCost: double.maxFinite * 0.75,
          processingPerRawUnit: 0,
          packagingPerProduct: 0,
          transportCost: double.maxFinite * 0.75,
        ),
        throwsArgumentError,
      );
    });

    test('allows large finite calculations when all derived values remain finite', () {
      final result = calculate(
        rawQuantity: double.maxFinite / 4,
        yieldPercent: 100,
        rawUnitCost: 0,
        processingPerRawUnit: 0,
        packagingPerProduct: 0,
        sellingPricePerProduct: 0,
      );

      expect(result.outputQuantity, double.maxFinite / 4);
      expect(result.totalCost, 0);
      expect(result.revenue, 0);
      expect(result.profitOrLoss, 0);
    });
  });
}
