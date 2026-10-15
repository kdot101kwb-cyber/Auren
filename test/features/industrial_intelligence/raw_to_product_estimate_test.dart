import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/industrial_intelligence/domain/raw_to_product_estimate.dart';

void main() {
  group('RawToProductEstimate.calculate', () {
    test('calculates output, costs, revenue and margin from user inputs', () {
      final result = RawToProductEstimate.calculate(
        rawQuantity: 1000,
        yieldPercent: 85,
        rawUnitCost: 1,
        processingPerRawUnit: 0.4,
        packagingPerProduct: 0.2,
        transportCost: 100,
        otherCosts: 50,
        sellingPricePerProduct: 3,
      );
      expect(result.outputQuantity, 850);
      expect(result.rawAndProcessingCost, 1400);
      expect(result.packagingCost, 170);
      expect(result.transportAndOtherCost, 150);
      expect(result.totalCost, 1720);
      expect(result.revenue, 2550);
      expect(result.profitOrLoss, 830);
      expect(result.unitCost, closeTo(1720 / 850, 0.000001));
      expect(result.salesMarginPercent, closeTo(830 / 2550 * 100, 0.000001));
    });

    test('supports the upper yield boundary of one hundred percent', () {
      final result = RawToProductEstimate.calculate(
        rawQuantity: 12,
        yieldPercent: 100,
        rawUnitCost: 2,
        processingPerRawUnit: 0.5,
        packagingPerProduct: 0.25,
        transportCost: 3,
        otherCosts: 1,
        sellingPricePerProduct: 4,
      );
      expect(result.outputQuantity, 12);
      expect(result.rawAndProcessingCost, 30);
      expect(result.packagingCost, 3);
      expect(result.transportAndOtherCost, 4);
      expect(result.totalCost, 37);
      expect(result.revenue, 48);
      expect(result.profitOrLoss, 11);
      expect(result.unitCost, closeTo(37 / 12, 0.000001));
      expect(result.salesMarginPercent, closeTo(11 / 48 * 100, 0.000001));
    });

    test('reports a loss and does not present negative margin as profit', () {
      final result = RawToProductEstimate.calculate(
        rawQuantity: 10,
        yieldPercent: 50,
        rawUnitCost: 5,
        processingPerRawUnit: 1,
        packagingPerProduct: 1,
        transportCost: 20,
        otherCosts: 10,
        sellingPricePerProduct: 1,
      );
      expect(result.profitOrLoss, lessThan(0));
      expect(result.salesMarginPercent, lessThan(0));
    });

    test('supports zero yield without division by zero', () {
      final result = RawToProductEstimate.calculate(
        rawQuantity: 10,
        yieldPercent: 0,
        rawUnitCost: 2,
        processingPerRawUnit: 1,
        packagingPerProduct: 1,
        transportCost: 0,
        otherCosts: 0,
        sellingPricePerProduct: 5,
      );
      expect(result.outputQuantity, 0);
      expect(result.unitCost, isNull);
      expect(result.revenue, 0);
      expect(result.salesMarginPercent, isNull);
      expect(result.profitOrLoss, -30);
    });

    test('zero raw quantity produces no output and undefined unit metrics', () {
      final result = RawToProductEstimate.calculate(
        rawQuantity: 0,
        yieldPercent: 85,
        rawUnitCost: 1,
        processingPerRawUnit: 0.4,
        packagingPerProduct: 0.2,
        transportCost: 0,
        otherCosts: 0,
        sellingPricePerProduct: 3,
      );
      expect(result.outputQuantity, 0);
      expect(result.totalCost, 0);
      expect(result.revenue, 0);
      expect(result.profitOrLoss, 0);
      expect(result.unitCost, isNull);
      expect(result.salesMarginPercent, isNull);
    });

    test('unit cost remains available but margin is undefined when selling price is zero', () {
      final result = RawToProductEstimate.calculate(
        rawQuantity: 10,
        yieldPercent: 50,
        rawUnitCost: 2,
        processingPerRawUnit: 1,
        packagingPerProduct: 0.5,
        transportCost: 1,
        otherCosts: 0,
        sellingPricePerProduct: 0,
      );
      expect(result.outputQuantity, 5);
      expect(result.unitCost, closeTo(6.7, 0.000001));
      expect(result.revenue, 0);
      expect(result.profitOrLoss, closeTo(-33.5, 0.000001));
      expect(result.salesMarginPercent, isNull);
    });

    test('reports exact break-even as zero profit and zero sales margin', () {
      final result = RawToProductEstimate.calculate(
        rawQuantity: 10,
        yieldPercent: 80,
        rawUnitCost: 2,
        processingPerRawUnit: 1,
        packagingPerProduct: 0.5,
        transportCost: 1,
        otherCosts: 0,
        sellingPricePerProduct: 4.375,
      );
      expect(result.outputQuantity, 8);
      expect(result.totalCost, 35);
      expect(result.revenue, 35);
      expect(result.profitOrLoss, 0);
      expect(result.salesMarginPercent, 0);
    });

    test('rejects calculations whose derived values overflow', () {
      expect(
        () => RawToProductEstimate.calculate(
          rawQuantity: double.maxFinite,
          yieldPercent: 100,
          rawUnitCost: 2,
          processingPerRawUnit: 0,
          packagingPerProduct: 0,
          transportCost: 0,
          otherCosts: 0,
          sellingPricePerProduct: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects overflow in combined fixed costs', () {
      expect(
        () => RawToProductEstimate.calculate(
          rawQuantity: 1,
          yieldPercent: 100,
          rawUnitCost: 0,
          processingPerRawUnit: 0,
          packagingPerProduct: 0,
          transportCost: double.maxFinite,
          otherCosts: double.maxFinite,
          sellingPricePerProduct: 1,
        ),
        throwsArgumentError,
      );
    });

    test('rejects overflow in a margin derived from an extremely small revenue', () {
      expect(
        () => RawToProductEstimate.calculate(
          rawQuantity: 1,
          yieldPercent: 100,
          rawUnitCost: double.maxFinite,
          processingPerRawUnit: 0,
          packagingPerProduct: 0,
          transportCost: 0,
          otherCosts: 0,
          sellingPricePerProduct: double.minPositive,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative, non-finite and out-of-range inputs', () {
      final base = <String, double>{
        'rawQuantity': 1,
        'yieldPercent': 80,
        'rawUnitCost': 1,
        'processingPerRawUnit': 0,
        'packagingPerProduct': 0,
        'transportCost': 0,
        'otherCosts': 0,
        'sellingPricePerProduct': 2,
      };
      void calculate(Map<String, double> values) =>
          RawToProductEstimate.calculate(
            rawQuantity: values['rawQuantity']!,
            yieldPercent: values['yieldPercent']!,
            rawUnitCost: values['rawUnitCost']!,
            processingPerRawUnit: values['processingPerRawUnit']!,
            packagingPerProduct: values['packagingPerProduct']!,
            transportCost: values['transportCost']!,
            otherCosts: values['otherCosts']!,
            sellingPricePerProduct: values['sellingPricePerProduct']!,
          );
      expect(() => calculate({...base, 'rawUnitCost': -1}), throwsArgumentError);
      expect(() => calculate({...base, 'yieldPercent': 101}), throwsArgumentError);
      expect(() => calculate({...base, 'rawQuantity': double.infinity}), throwsArgumentError);
      expect(() => calculate({...base, 'rawQuantity': -1}), throwsArgumentError);
    });
  });
}
