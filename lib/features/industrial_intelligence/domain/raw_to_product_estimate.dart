/// Transparent estimate from user-provided assumptions. This does not fetch
/// market prices or replace professional manufacturing/financial review.
class RawToProductEstimate {
  final double outputQuantity;
  final double rawAndProcessingCost;
  final double packagingCost;
  final double transportCost;
  final double otherCosts;
  final double transportAndOtherCost;
  final double totalCost;
  final double revenue;
  final double profitOrLoss;
  final double? unitCost;
  final double? salesMarginPercent;

  const RawToProductEstimate({
    required this.outputQuantity,
    required this.rawAndProcessingCost,
    required this.packagingCost,
    required this.transportCost,
    required this.otherCosts,
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
    // A unit cost is undefined when no usable product is produced.
    final double? unitCost =
        outputQuantity > 0 ? totalCost / outputQuantity : null;
    // A sales margin is undefined when there is no revenue to divide by.
    final double? salesMarginPercent =
        revenue > 0 ? profitOrLoss / revenue * 100 : null;

    final outputs = [
      outputQuantity,
      rawAndProcessingCost,
      packagingCost,
      transportAndOtherCost,
      totalCost,
      revenue,
      profitOrLoss,
      if (unitCost != null) unitCost,
      if (salesMarginPercent != null) salesMarginPercent,
    ];
    if (outputs.any((value) => !value.isFinite)) {
      throw ArgumentError('The estimate exceeds supported numeric limits.');
    }

    return RawToProductEstimate(
      outputQuantity: outputQuantity,
      rawAndProcessingCost: rawAndProcessingCost,
      packagingCost: packagingCost,
      transportCost: transportCost,
      otherCosts: otherCosts,
      transportAndOtherCost: transportAndOtherCost,
      totalCost: totalCost,
      revenue: revenue,
      profitOrLoss: profitOrLoss,
      unitCost: unitCost,
      salesMarginPercent: salesMarginPercent,
    );
  }
}
