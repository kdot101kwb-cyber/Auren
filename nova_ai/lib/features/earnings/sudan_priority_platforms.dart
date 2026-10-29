import 'package:flutter/foundation.dart';

enum SudanEarningAction {
  completeDailyCheck,
  publishOriginalContent,
  reviewBalance,
  verifyWithdrawal,
}

@immutable
class SudanPriorityPlatform {
  final String id;
  final String name;
  final String officialUrl;
  final String expectedAssetPath;
  final String suggestedRoutine;
  final String verificationWarning;
  final SudanEarningAction action;

  const SudanPriorityPlatform({
    required this.id,
    required this.name,
    required this.officialUrl,
    required this.expectedAssetPath,
    required this.suggestedRoutine,
    required this.verificationWarning,
    required this.action,
  });
}

/// User-requested shortlist. These are targets to investigate, not verified
/// Sudan payout guarantees. NOVA never stores exchange or wallet credentials.
const sudanPriorityPlatforms = <SudanPriorityPlatform>[
  SudanPriorityPlatform(
    id: 'pixels',
    name: 'Pixels',
    officialUrl: 'https://www.pixels.xyz/',
    expectedAssetPath: 'PIXEL / RON ecosystem -> exchange (availability varies)',
    suggestedRoutine: 'افحص المهام اليومية والرصيد؛ لا تشترِ RON أو PIXEL لفتح مكافآت.',
    verificationWarning: 'لم نثبت سحباً حديثاً من حساب سوداني إلى بنكك. تحقق من التوكن والشبكة ورسوم التحويل والتداول قبل الاعتماد عليه.',
    action: SudanEarningAction.completeDailyCheck,
  ),
  SudanPriorityPlatform(
    id: 'grass',
    name: 'Grass',
    officialUrl: 'https://www.getgrass.io/',
    expectedAssetPath: 'توكن/محفظة حسب شروط التوزيع والسحب الحالية',
    suggestedRoutine: 'تحقق من حالة العقد أو المكافآت الرسمية، ثم سجّل وقت التشغيل والرصيد.',
    verificationWarning: 'مكافآت الشبكة والـ airdrop ليست راتباً شهرياً مضموناً؛ افحص شروط السودان والسحب الحالية.',
    action: SudanEarningAction.reviewBalance,
  ),
  SudanPriorityPlatform(
    id: 'honeygain',
    name: 'Honeygain',
    officialUrl: 'https://www.honeygain.com/',
    expectedAssetPath: 'PayPal أو JumpTask بحسب إعداد الدفع المتاح',
    suggestedRoutine: 'راقب الرصيد واستهلاك البيانات؛ لا تترك مشاركة الإنترنت تعمل إذا كانت كلفة البيانات أعلى من العائد.',
    verificationWarning: 'الحد المعتاد لخيار Honeygain هو 20 دولاراً؛ خيار JumpTask ليس تأكيداً على USDT مباشر أو على السحب إلى بنكك.',
    action: SudanEarningAction.reviewBalance,
  ),
  SudanPriorityPlatform(
    id: 'publish0x',
    name: 'Publish0x',
    officialUrl: 'https://www.publish0x.com/',
    expectedAssetPath: 'الأصول وطرق السحب كما تظهر في لوحة الحساب الحالية',
    suggestedRoutine: 'انشر محتوى أصلياً مفيداً، راجع شروط المكافآت وحدود السحب قبل تخصيص وقت يومي.',
    verificationWarning: 'لم يتم تأكيد حد 0.50 دولار أو سحب يومي في السودان؛ لا تعتمد الأرقام المرسلة دون تحقق من لوحة الحساب.',
    action: SudanEarningAction.publishOriginalContent,
  ),
  SudanPriorityPlatform(
    id: 'hive',
    name: 'Hive Blog',
    officialUrl: 'https://hive.blog/',
    expectedAssetPath: 'HIVE / HBD -> منصة تدعم الإيداع والسحب الفعليين',
    suggestedRoutine: 'انشر محتوى أصلياً بانتظام وتابع المكافآت والسعر ورسوم التحويل.',
    verificationWarning: 'التصويت والمكافآت تختلف ولا تضمن دخلاً يومياً؛ تحقق من إتاحة الإيداع والسحب على المنصة التي ستستخدمها.',
    action: SudanEarningAction.publishOriginalContent,
  ),
];

List<SudanPriorityPlatform> filterSudanPriorityPlatforms(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return sudanPriorityPlatforms;
  return sudanPriorityPlatforms
      .where((platform) =>
          platform.name.toLowerCase().contains(q) ||
          platform.expectedAssetPath.toLowerCase().contains(q) ||
          platform.suggestedRoutine.toLowerCase().contains(q))
      .toList(growable: false);
}
