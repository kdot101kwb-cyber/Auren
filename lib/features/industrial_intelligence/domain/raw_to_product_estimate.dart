/// Transparent estimate from user-provided assumptions. This does not fetch
/// market prices or replace professional manufacturing/financial review.
class RawToProductEstimate {
  final double outputQuantity;
  final double rawAndProcessingCost;
  final double packagingCost;
  final double transportAndOtherCost;
  final double totalCost;
  final double revenue;
  final double profitOrLoss;
  final double unitCost;
  final double salesMarginPercent;

  const RawToProductEstimate({
    required this.outputQuantity,
    required this.rawAndProcessingCost,
    required this.packagingCost,
    required this.transportAndOtherCost,
    required this.totalCost,
    required this.revenue,
    required this.profitOrLoss,
    required this.unitCost,
    required this.salesMarginPercent,
  });

  static RawToProductEstimate calculate({
    required double rawQuantity,
    required double yieldPercent,
    required double rawUnitCost,
    required double processingPerRawUnit,
    required double packagingPerProduct,
    required double transportCost,
    required double otherCosts,
    required double sellingPricePerProduct,
  }) {
    final inputs = [
      rawQuantity,
      yieldPercent,
      rawUnitCost,
      processingPerRawUnit,
      packagingPerProduct,
      transportCost,
      otherCosts,
      sellingPricePerProduct,
    ];
    if (inputs.any((value) => !value.isFinite || value < 0)) {
      throw ArgumentError('All estimate inputs must be finite and non-negative.');
    }
    if (rawQuantity == 0) {
      throw ArgumentError.value(rawQuantity, 'rawQuantity', 'Must be greater than zero.');
    }
    if (yieldPercent > 100) {
      throw ArgumentError.value(yieldPercent, 'yieldPercent', 'Must be between 0 and 100.');
    }

    final outputQuantity = rawQuantity * yieldPercent / 100;
    final rawAndProcessingCost =
        rawQuantity * (rawUnitCost + processingPerRawUnit);
    final packagingCost = outputQuantity * packagingPerProduct;
    final transportAndOtherCost = transportCost + otherCosts;
    final totalCost =
        rawAndProcessingCost + packagingCost + transportAndOtherCost;
    final revenue = outputQuantity * sellingPricePerProduct;
    final profitOrLoss = revenue - totalCost;
    final unitCost = outputQuantity > 0 ? totalCost / outputQuantity : 0.0;
    final salesMarginPercent =
        revenue > 0 ? profitOrLoss / revenue * 100 : 0.0;

    final outputs = [
      outputQuantity,
      rawAndProcessingCost,
      packagingCost,
      transportAndOtherCost,
      totalCost,
      revenue,
      profitOrLoss,
      unitCost,
      salesMarginPercent,
    ];
    if (outputs.any((value) => !value.isFinite)) {
      throw ArgumentError('The estimate exceeds supported numeric limits.');
    }

    return RawToProductEstimate(
      outputQuantity: outputQuantity,
      rawAndProcessingCost: rawAndProcessingCost,
      packagingCost: packagingCost,
      transportAndOtherCost: transportAndOtherCost,
      totalCost: totalCost,
      revenue: revenue,
      profitOrLoss: profitOrLoss,
      unitCost: unitCost,
      salesMarginPercent: salesMarginPercent,
    );
  }
}
