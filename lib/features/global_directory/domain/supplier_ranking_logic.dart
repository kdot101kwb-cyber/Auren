/// Explainable supplier ranking for Business Navigator.
///
/// Scores are normalized to 0–100 and only use supplied, comparable data.
/// This helper does not verify a supplier or convert currencies.
class SupplierRankingCandidate {
  const SupplierRankingCandidate({
    required this.id,
    required this.name,
    required this.currency,
    this.price,
    this.shipping,
    this.leadTimeDays,
    this.minimumOrder,
    this.verified = false,
    this.rating,
  });

  final String id;
  final String name;
  final String currency;
  final double? price;
  final double? shipping;
  final int? leadTimeDays;
  final double? minimumOrder;
  final bool verified;
  final double? rating;

  double? get totalCost {
    final p = price;
    final s = shipping;
    if (p == null || s == null || !p.isFinite || !s.isFinite ||
        p < 0 || s < 0 || !(p + s).isFinite) {
      return null;
    }
    return p + s;
  }
}

class SupplierRankingResult {
  const SupplierRankingResult({
    required this.candidate,
    required this.score,
    required this.reasons,
    required this.warnings,
  });

  final SupplierRankingCandidate candidate;
  final double score;
  final List<String> reasons;
  final List<String> warnings;
}

class SupplierRankingLogic {
  const SupplierRankingLogic._();

  /// Ranks suppliers within the requested currency only. Missing data is not
  /// silently treated as a positive signal; it produces an explicit warning.
  static List<SupplierRankingResult> rank(
    Iterable<SupplierRankingCandidate> candidates, {
    required String currency,
    int? maxLeadTimeDays,
    double? maxBudget,
    double? maxMinimumOrder,
  }) {
    final requestedCurrency = currency.trim().toUpperCase();
    // A blank currency is not a comparable monetary unit. Never allow offers
    // with missing currency metadata to be ranked together as if they matched.
    if (requestedCurrency.isEmpty) {
      return const <SupplierRankingResult>[];
    }

    final sameCurrency = candidates
        .where((c) => c.currency.trim().toUpperCase() == requestedCurrency)
        .toList(growable: false);
    final validCosts = sameCurrency
        .map((c) => c.totalCost)
        .whereType<double>()
        .toList(growable: false);
    final minCost = validCosts.isEmpty
        ? null
        : validCosts.reduce((a, b) => a < b ? a : b);
    final maxCost = validCosts.isEmpty
        ? null
        : validCosts.reduce((a, b) => a > b ? a : b);

    final results = <SupplierRankingResult>[];
    for (final c in sameCurrency) {
      final reasons = <String>[];
      final warnings = <String>[];
      var score = 0.0;

      final cost = c.totalCost;
      if (cost == null) {
        warnings.add('missing_or_invalid_cost');
      } else if (minCost == maxCost) {
        score += 40;
        reasons.add('competitive_total_cost');
      } else {
        final costRange = maxCost! - minCost!;
        // totalCost is finite and non-negative, so this difference is finite.
        final normalizedCost = (maxCost - cost) / costRange;
        score += 40 * normalizedCost.clamp(0.0, 1.0);
        if (cost == minCost) reasons.add('lowest_comparable_total_cost');
      }

      if (maxLeadTimeDays != null && maxLeadTimeDays < 0) {
        warnings.add('invalid_max_lead_time_constraint');
      } else if (maxLeadTimeDays != null) {
        final days = c.leadTimeDays;
        if (days == null || days < 0) {
          warnings.add('missing_or_invalid_lead_time');
        } else if (days <= maxLeadTimeDays) {
          score += 20;
          reasons.add('meets_lead_time');
        }
      } else if (c.leadTimeDays == null || c.leadTimeDays! < 0) {
        warnings.add('missing_or_invalid_lead_time');
      }

      if (maxBudget != null) {
        if (cost == null) {
          if (!warnings.contains('missing_or_invalid_cost')) {
            warnings.add('missing_or_invalid_cost');
          }
        } else if (maxBudget.isFinite && maxBudget >= 0 && cost <= maxBudget) {
          score += 20;
          reasons.add('within_budget');
        } else {
          warnings.add('over_budget_or_invalid_budget');
        }
      } else if (cost != null) {
        score += 20;
      }

      if (maxMinimumOrder != null && 
          (!maxMinimumOrder.isFinite || maxMinimumOrder < 0)) {
        warnings.add('invalid_max_minimum_order_constraint');
      } else if (maxMinimumOrder != null) {
        final moq = c.minimumOrder;
        if (moq == null || !moq.isFinite || moq < 0) {
          warnings.add('missing_or_invalid_minimum_order');
        } else if (moq <= maxMinimumOrder) {
          score += 10;
          reasons.add('meets_minimum_order');
        } else {
          warnings.add('minimum_order_exceeds_requirement');
        }
      } else if (c.minimumOrder != null &&
          c.minimumOrder!.isFinite && c.minimumOrder! >= 0) {
        score += 10;
      } else {
        warnings.add('missing_or_invalid_minimum_order');
      }

      if (c.verified) {
        score += 5;
        reasons.add('marked_verified');
      } else {
        warnings.add('supplier_not_verified');
      }

      final rating = c.rating;
      if (rating == null || !rating.isFinite || rating < 0 || rating > 5) {
        warnings.add('missing_or_invalid_rating');
      } else {
        score += rating;
        reasons.add('rating_available');
      }

      results.add(SupplierRankingResult(
        candidate: c,
        score: score.clamp(0.0, 100.0).toDouble(),
        reasons: List.unmodifiable(reasons),
        warnings: List.unmodifiable(warnings),
      ));
    }

    results.sort((a, b) {
      final scoreOrder = b.score.compareTo(a.score);
      if (scoreOrder != 0) return scoreOrder;
      final aCost = a.candidate.totalCost;
      final bCost = b.candidate.totalCost;
      if (aCost != null && bCost != null) {
        final costOrder = aCost.compareTo(bCost);
        if (costOrder != 0) return costOrder;
      } else if (aCost != null) {
        return -1;
      } else if (bCost != null) {
        return 1;
      }
      final nameOrder = a.candidate.name.toLowerCase().compareTo(
          b.candidate.name.toLowerCase());
      if (nameOrder != 0) return nameOrder;
      return a.candidate.id.compareTo(b.candidate.id);
    });
    return List.unmodifiable(results);
  }
}
