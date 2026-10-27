/// Evidence-led advertising and sponsorship opportunity tracking for NOVA.
///
/// This model stores claims separately from verified outcomes. It deliberately
/// does not treat advertised rates or dashboard balances as money received.
enum VerificationStatus { unverified, checking, eligible, ineligible, paidOutVerified }

enum EvidenceLevel { none, platformClaim, userDocumented, independentlyVerified }

class AdOpportunity {
  const AdOpportunity({
    required this.id,
    required this.name,
    required this.sourceUrl,
    required this.status,
    required this.evidenceLevel,
    this.targetRegions = const <String>[],
    this.payoutMethods = const <String>[],
    this.advertisedRatePerThousand,
    this.rateCurrency = 'USD',
    this.minimumPayout,
    this.minimumPayoutCurrency = 'USD',
    this.startupCost = 0,
    this.estimatedHours = 0,
    this.lastCheckedAt,
    this.notes = '',
  })  : assert(startupCost >= 0),
        assert(estimatedHours >= 0),
        assert(advertisedRatePerThousand == null ||
            advertisedRatePerThousand >= 0),
        assert(minimumPayout == null || minimumPayout >= 0);

  final String id;
  final String name;
  final String sourceUrl;
  final VerificationStatus status;
  final EvidenceLevel evidenceLevel;
  final List<String> targetRegions;
  final List<String> payoutMethods;
  final double? advertisedRatePerThousand;
  final String rateCurrency;
  final double? minimumPayout;
  final String minimumPayoutCurrency;
  final double startupCost;
  final double estimatedHours;
  final DateTime? lastCheckedAt;
  final String notes;

  bool get isVerifiedForUse =>
      status == VerificationStatus.eligible ||
      status == VerificationStatus.paidOutVerified;

  bool get hasVerifiedPayout => status == VerificationStatus.paidOutVerified;

  /// Estimates gross earnings only; never represents a guaranteed payout.
  double? estimateGrossEarnings({required int eligibleViews}) {
    if (eligibleViews < 0) {
      throw ArgumentError.value(eligibleViews, 'eligibleViews',
          'Eligible views cannot be negative.');
    }
    final rate = advertisedRatePerThousand;
    if (rate == null) return null;
    return eligibleViews / 1000 * rate;
  }

  /// A transparent 0–100 screening score, not a prediction of income.
  ///
  /// Opportunities requiring upfront payment are penalized heavily. Unknown
  /// eligibility and unverified payout claims cannot receive a high score.
  int get screeningScore {
    var score = 0;
    if (sourceUrl.startsWith('https://')) score += 10;
    if (status == VerificationStatus.eligible) score += 25;
    if (status == VerificationStatus.paidOutVerified) score += 35;
    if (evidenceLevel == EvidenceLevel.platformClaim) score += 5;
    if (evidenceLevel == EvidenceLevel.userDocumented) score += 15;
    if (evidenceLevel == EvidenceLevel.independentlyVerified) score += 25;
    if (payoutMethods.isNotEmpty) score += 10;
    if (startupCost == 0) {
      score += 15;
    } else {
      score -= 30;
    }
    if (lastCheckedAt != null) {
      final age = DateTime.now().difference(lastCheckedAt!).inDays;
      if (age <= 7) score += 10;
      if (age > 30) score -= 10;
    }
    if (status == VerificationStatus.ineligible) score = 0;
    return score.clamp(0, 100).toInt();
  }

  AdOpportunity copyWith({
    VerificationStatus? status,
    EvidenceLevel? evidenceLevel,
    List<String>? targetRegions,
    List<String>? payoutMethods,
    DateTime? lastCheckedAt,
    String? notes,
  }) {
    return AdOpportunity(
      id: id,
      name: name,
      sourceUrl: sourceUrl,
      status: status ?? this.status,
      evidenceLevel: evidenceLevel ?? this.evidenceLevel,
      targetRegions: targetRegions ?? this.targetRegions,
      payoutMethods: payoutMethods ?? this.payoutMethods,
      advertisedRatePerThousand: advertisedRatePerThousand,
      rateCurrency: rateCurrency,
      minimumPayout: minimumPayout,
      minimumPayoutCurrency: minimumPayoutCurrency,
      startupCost: startupCost,
      estimatedHours: estimatedHours,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      notes: notes ?? this.notes,
    );
  }
}

/// Seed data is explicitly marked as platform claims, not verified payouts.
const initialAdOpportunities = <AdOpportunity>[
  AdOpportunity(
    id: '249ads',
    name: '249 Ads',
    sourceUrl: 'https://www.249ads.com/',
    status: VerificationStatus.checking,
    evidenceLevel: EvidenceLevel.platformClaim,
    targetRegions: <String>['Sudan', 'Gulf'],
    payoutMethods: <String>['Bankak', 'USDT (TRC20/BEP20)'],
    startupCost: 0,
    notes: 'Platform advertises Sudan/Gulf creator campaigns and payouts. '
        'Confirm Sudan creator eligibility, payout terms, and an actual '
        'successful withdrawal before treating this as an income source.',
  ),
];
