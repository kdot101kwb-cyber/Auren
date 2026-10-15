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
      expect(result.unitCost, 0);
      expect(result.revenue, 0);
      expect(result.salesMarginPercent, 0);
      expect(result.profitOrLoss, -30);
    });

    test('reports exact break-even as zero profit and zero sales margin', () {
      final result = RawToProductEstimate.calculate(
        rawQuantity: 10,
        yieldPercent: 80,
        rawUnitCost: 2,
        processingPerRawUnit: 1,
        packagingPerProduct: 0.5,
        transportCost: 20,
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
