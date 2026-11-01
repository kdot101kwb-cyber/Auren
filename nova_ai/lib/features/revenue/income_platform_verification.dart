/// Evidence-based gates for recommending income platforms to the owner.
/// Unknown is deliberately not treated as eligible or payable.
enum PlatformCountryStatus { eligible, unknown, unsupported }
enum PlatformPayoutStatus { verified, unknown, unavailable }
enum PlatformStartupCost { zero, unknown, paid }
enum PlatformRecommendation { readyToTest, researchOnly, doNotRecommend }

class IncomePlatformAssessment {
  final String platformName;
  final String countryCode;
  final PlatformCountryStatus countryStatus;
  final PlatformPayoutStatus payoutStatus;
  final String payoutMethod;
  final PlatformStartupCost startupCost;
  final String? countryEvidenceUrl;
  final String? payoutEvidenceUrl;
  final bool countryEvidenceIsOfficial;
  final bool payoutEvidenceIsOfficial;
  final DateTime? lastVerifiedAt;
  final String notes;

  const IncomePlatformAssessment({
    required this.platformName,
    required this.countryCode,
    required this.countryStatus,
    required this.payoutStatus,
    required this.payoutMethod,
    required this.startupCost,
    this.countryEvidenceUrl,
    this.payoutEvidenceUrl,
    this.countryEvidenceIsOfficial = false,
    this.payoutEvidenceIsOfficial = false,
    this.lastVerifiedAt,
    this.notes = '',
  });

  bool _isHttpsEvidence(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  bool hasCurrentOfficialEvidence({DateTime? now, Duration maxAge = const Duration(days: 30)}) {
    final checkedAt = lastVerifiedAt;
    if (!countryEvidenceIsOfficial ||
        !payoutEvidenceIsOfficial ||
        !_isHttpsEvidence(countryEvidenceUrl) ||
        !_isHttpsEvidence(payoutEvidenceUrl) ||
        checkedAt == null) {
      return false;
    }
    final currentTime = now ?? DateTime.now().toUtc();
    final age = currentTime.toUtc().difference(checkedAt.toUtc());
    return !age.isNegative && age <= maxAge;
  }

  PlatformRecommendation recommendation({DateTime? now}) {
    if (countryStatus == PlatformCountryStatus.unsupported ||
        payoutStatus == PlatformPayoutStatus.unavailable ||
        startupCost == PlatformStartupCost.paid) {
      return PlatformRecommendation.doNotRecommend;
    }
    if (countryStatus == PlatformCountryStatus.eligible &&
        payoutStatus == PlatformPayoutStatus.verified &&
        startupCost == PlatformStartupCost.zero &&
        payoutMethod.trim().isNotEmpty &&
        hasCurrentOfficialEvidence(now: now)) {
      return PlatformRecommendation.readyToTest;
    }
    return PlatformRecommendation.researchOnly;
  }

  bool canStartWithoutPayment({DateTime? now}) =>
      recommendation(now: now) == PlatformRecommendation.readyToTest;

  String get recommendationLabel => switch (recommendation()) {
        PlatformRecommendation.readyToTest => 'مؤهلة للاختبار بدون دفع مبدئي',
        PlatformRecommendation.researchOnly => 'تحتاج تحققاً قبل التوصية',
        PlatformRecommendation.doNotRecommend => 'لا تُوصى بها حالياً',
      };

  List<String> missingChecks({DateTime? now}) {
    final missing = <String>[];
    if (countryStatus == PlatformCountryStatus.unknown ||
        (countryStatus == PlatformCountryStatus.eligible &&
            (!_isHttpsEvidence(countryEvidenceUrl) || !countryEvidenceIsOfficial))) {
      missing.add('قبول المتقدمين من السودان مع رابط رسمي');
    }
    if (payoutStatus == PlatformPayoutStatus.unknown ||
        (payoutStatus == PlatformPayoutStatus.verified &&
            (!_isHttpsEvidence(payoutEvidenceUrl) ||
                !payoutEvidenceIsOfficial ||
                payoutMethod.trim().isEmpty))) {
      missing.add('وسيلة السحب ورابط شروط الدفع الرسمي');
    }
    if (startupCost == PlatformStartupCost.unknown) missing.add('التأكد من عدم وجود رسوم بدء أو تقديم');
    if (lastVerifiedAt == null || !hasCurrentOfficialEvidence(now: now)) {
      missing.add('تاريخ تحقق حديث لا يتجاوز 30 يوماً');
    }
    return List<String>.unmodifiable(missing);
  }
}
