import 'profile_mode_service.dart';

enum AurenProfileContext {
  social,
  content,
  work,
  business,
  discovery,
  education,
  travel,
  unknown,
}

extension AurenProfileContextX on AurenProfileContext {
  String get label {
    switch (this) {
      case AurenProfileContext.social: return 'Social';
      case AurenProfileContext.content: return 'Creator';
      case AurenProfileContext.work: return 'Work';
      case AurenProfileContext.business: return 'Business';
      case AurenProfileContext.discovery: return 'Discovery';
      case AurenProfileContext.education: return 'Education';
      case AurenProfileContext.travel: return 'Travel';
      case AurenProfileContext.unknown: return 'Auto';
    }
  }
}

class AurenAdaptiveProfileResult {
  final AurenProfileMode mode;
  final int confidence;
  final String reason;
  final List<AurenProfileMode> alternatives;

  const AurenAdaptiveProfileResult({
    required this.mode,
    required this.confidence,
    required this.reason,
    this.alternatives = const [],
  });
}

/// Lightweight on-device context engine.
///
/// It never changes the active mode by itself. The app can ask for a
/// recommendation and the user can accept it or keep the manually selected
/// mode.
class AurenAdaptiveProfileService {
  const AurenAdaptiveProfileService();

  AurenAdaptiveProfileResult suggest({
    required AurenProfileMode currentMode,
    AurenProfileContext context = AurenProfileContext.unknown,
    AurenProfileModeData? profile,
    String? intent,
  }) {
    final text = _normalize([
      intent ?? '',
      profile?.headline ?? '',
      profile?.bio ?? '',
      ...(profile?.skills ?? const <String>[]),
      ...(profile?.interests ?? const <String>[]),
      ...(profile?.goals ?? const <String>[]),
      ...(profile?.services ?? const <String>[]),
    ].join(' '));

    AurenProfileMode? detected;
    String reason;

    switch (context) {
      case AurenProfileContext.business:
        detected = AurenProfileMode.business;
        reason = 'السياق الحالي يركز على المنتجات والخدمات والعملاء والنمو.';
        break;
      case AurenProfileContext.work:
        detected = AurenProfileMode.professional;
        reason = 'السياق الحالي يركز على المهارات والخبرة والفرص المهنية.';
        break;
      case AurenProfileContext.content:
        detected = AurenProfileMode.creator;
        reason = 'السياق الحالي يركز على إنشاء المحتوى والجمهور.';
        break;
      case AurenProfileContext.social:
        detected = AurenProfileMode.personal;
        reason = 'السياق الحالي يركز على التواصل والاهتمامات الشخصية.';
        break;
      case AurenProfileContext.discovery:
      case AurenProfileContext.education:
      case AurenProfileContext.travel:
      case AurenProfileContext.unknown:
        detected = _fromText(text);
        reason = detected == null
            ? 'لا توجد إشارة قوية؛ سيبقى الوضع الحالي كما هو.'
            : 'AUREN وجد إشارات من اهتماماتك وأهدافك تناسب هذا الوضع.';
        break;
    }

    final selected = detected ?? currentMode;
    final confidence = detected == null
        ? 100
        : selected == currentMode
            ? 95
            : _confidence(context, text, selected);

    return AurenAdaptiveProfileResult(
      mode: selected,
      confidence: confidence,
      reason: reason,
      alternatives: _alternatives(selected),
    );
  }

  AurenProfileMode? _fromText(String text) {
    if (_hasAny(text, const [
      'business', 'company', 'customer', 'client', 'product', 'service',
      'بيع', 'شركة', 'عملاء', 'منتج', 'خدمة', 'تجارة', 'مشروع',
    ])) return AurenProfileMode.business;

    if (_hasAny(text, const [
      'creator', 'content', 'video', 'podcast', 'music', 'audience',
      'محتوى', 'فيديو', 'موسيقى', 'جمهور', 'تصوير',
    ])) return AurenProfileMode.creator;

    if (_hasAny(text, const [
      'job', 'career', 'skill', 'freelance', 'professional', 'work',
      'وظيفة', 'مهنة', 'مهارة', 'عمل', 'فرصة', 'خبرة',
    ])) return AurenProfileMode.professional;

    return null;
  }

  String _normalize(String value) {
    var text = value.toLowerCase();
    const marks = '\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0670';
    for (final mark in marks.runes) {
      text = text.replaceAll(String.fromCharCode(mark), '');
    }
    text = text
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ـ', ' ');
    return text.replaceAll(RegExp(r'\\s+'), ' ').trim();
  }

  bool _hasAny(String text, List<String> terms) =>
      terms.any((term) => text.contains(_normalize(term)));

  int _confidence(
    AurenProfileContext context,
    String text,
    AurenProfileMode mode,
  ) {
    if (context != AurenProfileContext.unknown) return 92;
    final signals = <AurenProfileMode, List<String>>{
      AurenProfileMode.business: const ['business', 'company', 'customer', 'product', 'service', 'شركة', 'عملاء', 'منتج', 'خدمة'],
      AurenProfileMode.creator: const ['creator', 'content', 'video', 'music', 'audience', 'محتوى', 'فيديو', 'موسيقى', 'جمهور'],
      AurenProfileMode.professional: const ['job', 'career', 'skill', 'work', 'وظيفة', 'مهنة', 'مهارة', 'فرصة'],
    };
    final count = signals[mode]?.where(text.contains).length ?? 0;
    return (68 + count * 8).clamp(68, 92).toInt();
  }

  List<AurenProfileMode> _alternatives(AurenProfileMode selected) =>
      AurenProfileMode.values.where((m) => m != selected).take(2).toList();
}
