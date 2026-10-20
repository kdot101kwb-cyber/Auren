import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/industrial_intelligence/domain/raw_to_product_estimate.dart';

void main() {
  group('RawToProductEstimate boundary behavior', () {
    RawToProductEstimate calculate({
      double rawQuantity = 10,
      double yieldPercent = 50,
      double rawUnitCost = 2,
      double processingPerRawUnit = 1,
      double packagingPerProduct = 0.5,
      double transportCost = 3,
      double otherCosts = 2,
      double sellingPricePerProduct = 5,
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

    test('calculates output, total cost, profit, and margin consistently', () {
      final estimate = calculate();

      expect(estimate.outputQuantity, 5);
      expect(estimate.rawAndProcessingCost, 30);
      expect(estimate.packagingCost, 2.5);
      expect(estimate.transportAndOtherCost, 5);
      expect(estimate.totalCost, 37.5);
      expect(estimate.revenue, 25);
      expect(estimate.profitOrLoss, -12.5);
      expect(estimate.unitCost, 7.5);
      expect(estimate.salesMarginPercent, -50);
    });

    test('zero yield produces zero output and leaves unit metrics undefined', () {
      final estimate = calculate(yieldPercent: 0);

      expect(estimate.outputQuantity, 0);
      expect(estimate.revenue, 0);
      expect(estimate.unitCost, isNull);
      expect(estimate.salesMarginPercent, isNull);
      expect(estimate.profitOrLoss, -35);
    });

    test('zero selling price leaves sales margin undefined without hiding loss', () {
      final estimate = calculate(sellingPricePerProduct: 0);

      expect(estimate.revenue, 0);
      expect(estimate.salesMarginPercent, isNull);
      expect(estimate.profitOrLoss, -37.5);
    });

    test('zero raw quantity is accepted and produces no fabricated revenue', () {
      final estimate = calculate(rawQuantity: 0);

      expect(estimate.outputQuantity, 0);
      expect(estimate.rawAndProcessingCost, 0);
      expect(estimate.packagingCost, 0);
      expect(estimate.revenue, 0);
      expect(estimate.unitCost, isNull);
      expect(estimate.salesMarginPercent, isNull);
    });

    test('100 percent yield preserves the full raw quantity', () {
      final estimate = calculate(rawQuantity: 12.5, yieldPercent: 100);

      expect(estimate.outputQuantity, 12.5);
      expect(estimate.packagingCost, 6.25);
      expect(estimate.revenue, 62.5);
    });

    test('rejects yield above the documented 0-to-100 range', () {
      expect(() => calculate(yieldPercent: 100.0001), throwsArgumentError);
    });

    test('rejects non-finite yield and negative quantity', () {
      expect(() => calculate(yieldPercent: double.nan), throwsArgumentError);
      expect(() => calculate(yieldPercent: double.infinity), throwsArgumentError);
      expect(() => calculate(rawQuantity: -0.01), throwsArgumentError);
    });
  });
}
