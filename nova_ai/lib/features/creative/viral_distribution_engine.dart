/// NOVA Viral Distribution Engine — deterministic first slice.
///
/// This module ranks manually supplied trend/content signals. It does not
/// scrape platforms, predict virality, generate media, or publish content.
class ViralSignal {
  final String topic;
  final String sourceUrl;
  final DateTime observedAt;
  final double momentum; // 0..100, only when measured from comparable snapshots
  final double audienceFit; // 0..100
  final double shareability; // 0..100
  final double retentionPotential; // 0..100
  final double evidenceConfidence; // 0..100
  final double competition; // 0..100
  final double productionCost; // 0..100
  final bool rightsCleared;

  const ViralSignal({
    required this.topic,
    required this.sourceUrl,
    required this.observedAt,
    required this.momentum,
    required this.audienceFit,
    required this.shareability,
    required this.retentionPotential,
    required this.evidenceConfidence,
    required this.competition,
    required this.productionCost,
    this.rightsCleared = false,
  });

  void validate() {
    if (topic.trim().isEmpty) {
      throw ArgumentError.value(topic, 'topic', 'must not be empty');
    }
    if (sourceUrl.trim().isEmpty) {
      throw ArgumentError.value(sourceUrl, 'sourceUrl', 'must identify the evidence source');
    }
    for (final entry in <String, double>{
      'momentum': momentum,
      'audienceFit': audienceFit,
      'shareability': shareability,
      'retentionPotential': retentionPotential,
      'evidenceConfidence': evidenceConfidence,
      'competition': competition,
      'productionCost': productionCost,
    }.entries) {
      if (!entry.value.isFinite || entry.value < 0 || entry.value > 100) {
        throw ArgumentError.value(entry.value, entry.key, 'must be between 0 and 100');
      }
    }
  }
}

class ViralScore {
  final ViralSignal signal;
  final double score;
  final String recommendation;
  final List<String> blockers;

  const ViralScore({
    required this.signal,
    required this.score,
    required this.recommendation,
    required this.blockers,
  });
}

/// Scores a signal using explainable weights and a recency decay.
///
/// The score is a prioritization heuristic, not a probability of going viral.
/// Future timestamps are rejected so clock/data errors are not rewarded.
ViralScore scoreViralSignal(
  ViralSignal signal, {
  required DateTime now,
}) {
  signal.validate();
  if (signal.observedAt.isAfter(now)) {
    throw ArgumentError.value(signal.observedAt, 'observedAt', 'cannot be in the future');
  }

  final ageHours = now.difference(signal.observedAt).inHours;
  final recency = (100 - (ageHours / 72 * 100)).clamp(0, 100).toDouble();
  final raw = signal.momentum * .20 +
      recency * .10 +
      signal.audienceFit * .20 +
      signal.shareability * .15 +
      signal.retentionPotential * .15 +
      signal.evidenceConfidence * .10 +
      (100 - signal.competition) * .05 +
      (100 - signal.productionCost) * .05;
  final score = double.parse(raw.toStringAsFixed(1));

  final blockers = <String>[];
  if (signal.evidenceConfidence < 40) blockers.add('الأدلة ضعيفة؛ تحقق من الاتجاه بمصدر مستقل');
  if (ageHours > 72) blockers.add('الإشارة أقدم من 72 ساعة؛ أعد التحقق');
  if (!signal.rightsCleared) blockers.add('حقوق الصور والصوت والمقاطع لم تُراجع');
  if (signal.sourceUrl.trim().isEmpty) blockers.add('لا يوجد مصدر يمكن مراجعته');

  final recommendation = blockers.isNotEmpty
      ? 'مراجعة مطلوبة قبل الإنتاج'
      : score >= 75
          ? 'أولوية اختبار إنتاجي صغير'
          : score >= 55
              ? 'اختبر زاوية مختلفة قبل التوسع'
              : 'أجّل الفكرة أو اجمع إشارات أفضل';

  return ViralScore(
    signal: signal,
    score: score,
    recommendation: recommendation,
    blockers: List<String>.unmodifiable(blockers),
  );
}

List<ViralScore> rankViralSignals(
  Iterable<ViralSignal> signals, {
  required DateTime now,
}) {
  final ranked = signals
      .map((signal) => scoreViralSignal(signal, now: now))
      .toList()
    ..sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.signal.topic.compareTo(b.signal.topic);
    });
  return List<ViralScore>.unmodifiable(ranked);
}

/// A recurring original character concept for AUREN Story Universe.
/// A character is a creative asset, not a real person's likeness.
class VirtualCharacterConcept {
  final String id;
  final String name;
  final String role;
  final String visualIdentity;
  final String personality;
  final String recurringHook;
  final String originalityNotes;

  const VirtualCharacterConcept({
    required this.id,
    required this.name,
    required this.role,
    required this.visualIdentity,
    required this.personality,
    required this.recurringHook,
    required this.originalityNotes,
  });

  void validate() {
    final fields = <String, String>{
      'id': id,
      'name': name,
      'role': role,
      'visualIdentity': visualIdentity,
      'personality': personality,
      'recurringHook': recurringHook,
      'originalityNotes': originalityNotes,
    };
    for (final entry in fields.entries) {
      if (entry.value.trim().isEmpty) {
        throw ArgumentError.value(entry.value, entry.key, 'must not be empty');
      }
    }
  }
}

/// Platform-specific draft instructions only. Posting is always a separate,
/// explicitly approved operation through an official platform integration.
class DistributionDraft {
  final String platform;
  final String format;
  final String captionGuidance;
  final bool approvalRequired;

  const DistributionDraft({
    required this.platform,
    required this.format,
    required this.captionGuidance,
    this.approvalRequired = true,
  });
}

List<DistributionDraft> buildDistributionDrafts(String coreIdea) {
  if (coreIdea.trim().isEmpty) {
    throw ArgumentError.value(coreIdea, 'coreIdea', 'must not be empty');
  }
  return List<DistributionDraft>.unmodifiable([
    const DistributionDraft(
      platform: 'YouTube Shorts',
      format: '9:16 vertical; strong first-second hook; clear ending',
      captionGuidance: 'عنوان قابل للبحث ووصف مختصر ووسوم قليلة وذات صلة',
    ),
    const DistributionDraft(
      platform: 'TikTok',
      format: '9:16 vertical; native pacing; immediate visual premise',
      captionGuidance: 'تعليق قصير بصوت الشخصية وسؤال يشجع التعليقات',
    ),
    const DistributionDraft(
      platform: 'Instagram Reels',
      format: '9:16 vertical; clean safe-zone captions; shareable payoff',
      captionGuidance: 'وصف قصير قابل للمشاركة مع غلاف واضح',
    ),
    const DistributionDraft(
      platform: 'X',
      format: 'Native video cut or teaser with context',
      captionGuidance: 'سطر افتتاحي يوضح الفكرة ورابط النسخة الكاملة عند توفرها',
    ),
  ]);
}
