import 'package:flutter/foundation.dart';

enum EarningPayoutStatus {
  cryptoClaimed,
  cryptoIndirect,
  noDirectCryptoEvidence,
}

@immutable
class EarningPlatform {
  final String id;
  final String name;
  final String url;
  final String workType;
  final String payoutNote;
  final String sudanNote;
  final EarningPayoutStatus payoutStatus;

  const EarningPlatform({
    required this.id,
    required this.name,
    required this.url,
    required this.workType,
    required this.payoutNote,
    required this.sudanNote,
    required this.payoutStatus,
  });
}

/// A cautious starter list, not a list of guaranteed jobs or guaranteed payouts.
/// Statuses describe publicly stated methods, not a confirmed payout to this user.
const earningPlatforms = <EarningPlatform>[
  EarningPlatform(
    id: 'microworkjobs',
    name: 'MicroWorkJobs',
    url: 'https://www.microworkjobs.com/help/migration',
    workType: 'مهام صغيرة، إدخال بيانات، اختبارات تطبيقات',
    payoutNote: 'الموقع يعلن عن سحب من 2 دولار، ويذكر USDT ضمن الطرق المتاحة حسب البلد.',
    sudanNote: 'قبول السودان وطريقة USDT الفعلية يجب تأكيدهما داخل الحساب قبل أداء المهام.',
    payoutStatus: EarningPayoutStatus.cryptoClaimed,
  ),
  EarningPlatform(
    id: 'jumptask',
    name: 'JumpTask',
    url: 'https://jumptask.io/payouts/',
    workType: 'مهام رقمية ومكافآت',
    payoutNote: 'يعلن عن Bitcoin وEthereum وTron وUSDC؛ لم يُؤكد USDT مباشرة.',
    sudanNote: 'الموقع يذكر أكثر من 100 دولة، لكن خيارات السحب المتاحة للحساب السوداني يجب فحصها.',
    payoutStatus: EarningPayoutStatus.cryptoIndirect,
  ),
  EarningPlatform(
    id: 'honeygain',
    name: 'Honeygain',
    url: 'https://www.honeygain.com/terms-of-use/',
    workType: 'مشاركة اتصال الإنترنت ومكافآت',
    payoutNote: 'السحب المعتاد من 20 دولاراً؛ خيار JumpTask يستخدم طرق الكريبتو المتاحة لدى JumpTask.',
    sudanNote: 'السودان ليس ضمن قائمة الحظر المنشورة التي راجعناها، لكن دعم طريقة السحب غير مضمون.',
    payoutStatus: EarningPayoutStatus.cryptoIndirect,
  ),
  EarningPlatform(
    id: 'sproutgigs',
    name: 'SproutGigs',
    url: 'https://sproutgigs.com/pricing.php',
    workType: 'مهام صغيرة وخدمات مصغرة',
    payoutNote: 'رسوم السحب متغيرة؛ لا نملك تأكيداً عاماً على USDT أو شبكة محددة.',
    sudanNote: 'افحص وسائل السحب الظاهرة بعد التسجيل المجاني وقبل تنفيذ المهام.',
    payoutStatus: EarningPayoutStatus.noDirectCryptoEvidence,
  ),
  EarningPlatform(
    id: 'microworkers',
    name: 'Microworkers',
    url: 'https://www.microworkers.com/faq.php',
    workType: 'مهام صغيرة وتقييم بيانات',
    payoutNote: 'الطرق المنشورة تشمل مزودي دفع مثل Airtm وPayPal وSkrill وPayoneer؛ ليس سحب Trust Wallet مباشراً مثبتاً.',
    sudanNote: 'تحقق من توفر مزود الدفع في السودان والحد الأدنى والرسوم.',
    payoutStatus: EarningPayoutStatus.noDirectCryptoEvidence,
  ),
  EarningPlatform(
    id: 'cashinstyle',
    name: 'CashInStyle',
    url: 'https://cashinstyle.com/page/faq',
    workType: 'استبيانات وعروض مكافآت',
    payoutNote: 'طرق السحب وشروطها تعتمد على الحساب؛ لا نؤكد USDT إلى Trust Wallet.',
    sudanNote: 'السودان غير ظاهر ضمن قائمة الاستثناءات المنشورة في صفحة FAQ التي راجعناها؛ هذا لا يثبت توفر العروض أو الدفع.',
    payoutStatus: EarningPayoutStatus.noDirectCryptoEvidence,
  ),
  EarningPlatform(
    id: 'paidwork',
    name: 'Paidwork',
    url: 'https://support.paidwork.com/',
    workType: 'مهام واستبيانات ومحتوى',
    payoutNote: 'المعلومات التي راجعناها تذكر PayPal والتحويل البنكي وبطاقات الهدايا؛ لا يوجد تأكيد على USDT المباشر.',
    sudanNote: 'افحص دعم بلد الإقامة وطرق الدفع المتاحة لحسابك.',
    payoutStatus: EarningPayoutStatus.noDirectCryptoEvidence,
  ),
  EarningPlatform(
    id: 'oneforma',
    name: 'OneForma',
    url: 'https://www.oneforma.com/jobs/',
    workType: 'بيانات ولغات وتقييمات للذكاء الاصطناعي',
    payoutNote: 'وسيلة الدفع تختلف حسب المشروع والبلد؛ لا نؤكد سحب Trust Wallet.',
    sudanNote: 'تحقق من شروط المشروع وبلد الإقامة وطريقة الدفع قبل الاختبار.',
    payoutStatus: EarningPayoutStatus.noDirectCryptoEvidence,
  ),
  EarningPlatform(
    id: 'crowdgen',
    name: 'CrowdGen by Appen',
    url: 'https://crowdgen.com/',
    workType: 'مشاريع بيانات وصوت ولغات',
    payoutNote: 'طرق الدفع تعتمد على المشروع والبلد؛ لا نؤكد USDT إلى Trust Wallet.',
    sudanNote: 'لا تبدأ اختباراً طويلاً قبل تأكيد أهلية السودان ووسيلة الدفع للمشروع.',
    payoutStatus: EarningPayoutStatus.noDirectCryptoEvidence,
  ),
  EarningPlatform(
    id: 'toloka',
    name: 'Toloka',
    url: 'https://toloka.ai/tolokers/',
    workType: 'تصنيف بيانات ومهام قصيرة',
    payoutNote: 'طرق السحب والتوفر تختلف حسب البلد والحساب؛ لا نؤكد USDT المباشر.',
    sudanNote: 'افحص خيارات الدفع الظاهرة في حسابك قبل الاستثمار في التدريب أو المهام.',
    payoutStatus: EarningPayoutStatus.noDirectCryptoEvidence,
  ),
];

List<EarningPlatform> filterEarningPlatforms({
  String query = '',
  bool cryptoOnly = false,
  Iterable<EarningPlatform> platforms = earningPlatforms,
}) {
  final normalized = query.trim().toLowerCase();
  return platforms.where((platform) {
    final matchesQuery = normalized.isEmpty ||
        platform.name.toLowerCase().contains(normalized) ||
        platform.workType.toLowerCase().contains(normalized) ||
        platform.payoutNote.toLowerCase().contains(normalized);
    final matchesCrypto = !cryptoOnly ||
        platform.payoutStatus != EarningPayoutStatus.noDirectCryptoEvidence;
    return matchesQuery && matchesCrypto;
  }).toList(growable: false);
}
