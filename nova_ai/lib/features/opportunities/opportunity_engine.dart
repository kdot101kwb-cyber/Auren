/// Transparent, deterministic scoring for business opportunities.
///
/// Inputs are normalized to 0..100. This is a prioritization heuristic, not
/// a prediction of income or a substitute for market validation.
class OpportunityCandidate {
  final String name;
  final String evidence;
  final double demand;
  final double trend;
  final double monetization;
  final double evidenceStrength;
  final double competition;
  final double executionCost;

  const OpportunityCandidate({
    required this.name,
    required this.evidence,
    required this.demand,
    required this.trend,
    required this.monetization,
    required this.evidenceStrength,
    required this.competition,
    required this.executionCost,
  });

  void validate() {
    if (name.trim().isEmpty) throw ArgumentError.value(name, 'name', 'must not be empty');
    for (final entry in <String, double>{
      'demand': demand,
      'trend': trend,
      'monetization': monetization,
      'evidenceStrength': evidenceStrength,
      'competition': competition,
      'executionCost': executionCost,
    }.entries) {
      if (!entry.value.isFinite || entry.value < 0 || entry.value > 100) {
        throw ArgumentError.value(entry.value, entry.key, 'must be between 0 and 100');
      }
    }
  }

  /// Higher is better. Competition and cost are inverted.
  double get score {
    validate();
    final raw = demand * .25 +
        trend * .15 +
        monetization * .20 +
        evidenceStrength * .20 +
        (100 - competition) * .10 +
        (100 - executionCost) * .10;
    return double.parse(raw.toStringAsFixed(1));
  }

  String get recommendation {
    final value = score;
    if (evidenceStrength < 35) return 'اجمع أدلة أكثر قبل الاستثمار';
    if (value >= 75) return 'اختبرها بتجربة صغيرة ومحددة';
    if (value >= 55) return 'حسّن العرض واختبر الطلب';
    return 'أجّلها أو غيّر الفرضية';
  }
}

/// A transparent revenue scenario based only on values supplied by the user.
class RevenueScenario {
  final double expectedCustomers;
  final double revenuePerCustomer;
  final double directCosts;
  final double otherCosts;

  const RevenueScenario({
    required this.expectedCustomers,
    required this.revenuePerCustomer,
    required this.directCosts,
    required this.otherCosts,
  });

  void validate() {
    for (final entry in <String, double>{
      'expectedCustomers': expectedCustomers,
      'revenuePerCustomer': revenuePerCustomer,
      'directCosts': directCosts,
      'otherCosts': otherCosts,
    }.entries) {
      if (!entry.value.isFinite || entry.value < 0) {
        throw ArgumentError.value(entry.value, entry.key, 'must be finite and non-negative');
      }
    }
  }

  double get grossRevenue {
    validate();
    return expectedCustomers * revenuePerCustomer;
  }

  double get estimatedProfit {
    validate();
    return grossRevenue - directCosts - otherCosts;
  }

  double get marginPercent {
    validate();
    if (grossRevenue == 0) return 0;
    return estimatedProfit / grossRevenue * 100;
  }
}

/// Sorts best-first; ties are deterministic by name.
List<OpportunityCandidate> rankOpportunities(Iterable<OpportunityCandidate> candidates) {
  final result = candidates.toList();
  for (final candidate in result) {
    candidate.validate();
  }
  result.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.name.compareTo(b.name);
  });
  return List<OpportunityCandidate>.unmodifiable(result);
}
