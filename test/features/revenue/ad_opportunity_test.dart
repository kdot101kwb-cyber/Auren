import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/revenue/models/ad_opportunity.dart';

void main() {
  group('AdOpportunity', () {
    const opportunity = AdOpportunity(
      id: 'test',
      name: 'Test network',
      sourceUrl: 'https://example.com',
      status: VerificationStatus.checking,
      evidenceLevel: EvidenceLevel.platformClaim,
      advertisedRatePerThousand: 6,
    );

    test('estimates gross earnings without implying guaranteed payout', () {
      expect(opportunity.estimateGrossEarnings(eligibleViews: 2500), 15);
    });

    test('returns null when advertised rate is unknown', () {
      const unknownRate = AdOpportunity(
        id: 'unknown',
        name: 'Unknown',
        sourceUrl: 'https://example.com',
        status: VerificationStatus.checking,
        evidenceLevel: EvidenceLevel.none,
      );
      expect(unknownRate.estimateGrossEarnings(eligibleViews: 1000), isNull);
    });

    test('rejects negative view counts', () {
      expect(
        () => opportunity.estimateGrossEarnings(eligibleViews: -1),
        throwsArgumentError,
      );
    });

    test('does not mark platform claims as verified payouts', () {
      expect(opportunity.isVerifiedForUse, isFalse);
      expect(opportunity.hasVerifiedPayout, isFalse);
    });

    test('ineligible opportunity receives zero screening score', () {
      final blocked = opportunity.copyWith(
        status: VerificationStatus.ineligible,
      );
      expect(blocked.screeningScore, 0);
    });

    test('copyWith updates verification without losing source facts', () {
      final updated = opportunity.copyWith(
        status: VerificationStatus.eligible,
        evidenceLevel: EvidenceLevel.userDocumented,
      );
      expect(updated.id, 'test');
      expect(updated.advertisedRatePerThousand, 6);
      expect(updated.status, VerificationStatus.eligible);
      expect(updated.evidenceLevel, EvidenceLevel.userDocumented);
    });

    test('seed entry keeps 249 Ads as checking, not verified', () {
      final entry = initialAdOpportunities.single;
      expect(entry.id, '249ads');
      expect(entry.status, VerificationStatus.checking);
      expect(entry.hasVerifiedPayout, isFalse);
      expect(entry.startupCost, 0);
    });
  });
}
