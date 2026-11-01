import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/revenue/income_platform_verification.dart';

void main() {
  final now = DateTime.utc(2026, 11, 1, 12);

  IncomePlatformAssessment assessment({
    PlatformCountryStatus country = PlatformCountryStatus.unknown,
    PlatformPayoutStatus payout = PlatformPayoutStatus.unknown,
    PlatformStartupCost cost = PlatformStartupCost.zero,
    String? countryUrl,
    String? payoutUrl,
    bool countryOfficial = false,
    bool payoutOfficial = false,
    String method = '',
    DateTime? checkedAt,
  }) => IncomePlatformAssessment(
    platformName: 'Example platform',
    countryCode: 'SD',
    countryStatus: country,
    payoutStatus: payout,
    payoutMethod: method,
    startupCost: cost,
    countryEvidenceUrl: countryUrl,
    payoutEvidenceUrl: payoutUrl,
    countryEvidenceIsOfficial: countryOfficial,
    payoutEvidenceIsOfficial: payoutOfficial,
    lastVerifiedAt: checkedAt,
  );

  test('unknown country or payout is research-only, never ready to recommend', () {
    final item = assessment();
    expect(item.recommendation(now: now), PlatformRecommendation.researchOnly);
    expect(item.canStartWithoutPayment(now: now), isFalse);
    expect(item.missingChecks(now: now), contains('قبول المتقدمين من السودان مع رابط رسمي'));
    expect(item.missingChecks(now: now), contains('وسيلة السحب ورابط شروط الدفع الرسمي'));
  });

  test('ready requires country, payout, zero cost and recent HTTPS evidence', () {
    final item = assessment(
      country: PlatformCountryStatus.eligible,
      payout: PlatformPayoutStatus.verified,
      method: 'Verified bank transfer',
      countryUrl: 'https://official.example/countries',
      payoutUrl: 'https://official.example/payouts',
      countryOfficial: true,
      payoutOfficial: true,
      checkedAt: now.subtract(const Duration(days: 2)),
    );
    expect(item.recommendation(now: now), PlatformRecommendation.readyToTest);
    expect(item.canStartWithoutPayment(now: now), isTrue);
  });

  test('stale, missing, or non-HTTPS evidence cannot unlock recommendation', () {
    final stale = assessment(
      country: PlatformCountryStatus.eligible,
      payout: PlatformPayoutStatus.verified,
      method: 'Bank transfer',
      countryUrl: 'https://official.example/countries',
      payoutUrl: 'https://official.example/payouts',
      checkedAt: now.subtract(const Duration(days: 31)),
    );
    final insecure = assessment(
      country: PlatformCountryStatus.eligible,
      payout: PlatformPayoutStatus.verified,
      method: 'Bank transfer',
      countryUrl: 'http://official.example/countries',
      payoutUrl: 'https://official.example/payouts',
      countryOfficial: true,
      payoutOfficial: true,
      checkedAt: now,
    );
    expect(stale.recommendation(now: now), PlatformRecommendation.researchOnly);
    expect(insecure.recommendation(now: now), PlatformRecommendation.researchOnly);
  });

  test('HTTPS links alone are not accepted without official-source attestation', () {
    final item = assessment(
      country: PlatformCountryStatus.eligible,
      payout: PlatformPayoutStatus.verified,
      method: 'Bank transfer',
      countryUrl: 'https://example.com/countries',
      payoutUrl: 'https://example.com/payouts',
      checkedAt: now,
    );
    expect(item.recommendation(now: now), PlatformRecommendation.researchOnly);
  });

  test('unsupported country, unavailable payout, or paid startup is excluded', () {
    expect(assessment(country: PlatformCountryStatus.unsupported).recommendation(now: now),
        PlatformRecommendation.doNotRecommend);
    expect(assessment(payout: PlatformPayoutStatus.unavailable).recommendation(now: now),
        PlatformRecommendation.doNotRecommend);
    expect(assessment(cost: PlatformStartupCost.paid).recommendation(now: now),
        PlatformRecommendation.doNotRecommend);
  });

  test('future verification timestamp is rejected', () {
    final item = assessment(
      country: PlatformCountryStatus.eligible,
      payout: PlatformPayoutStatus.verified,
      method: 'Bank transfer',
      countryUrl: 'https://official.example/countries',
      payoutUrl: 'https://official.example/payouts',
      countryOfficial: true,
      payoutOfficial: true,
      checkedAt: now.add(const Duration(days: 1)),
    );
    expect(item.recommendation(now: now), PlatformRecommendation.researchOnly);
  });
}
