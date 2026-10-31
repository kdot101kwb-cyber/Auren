import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/creative/viral_distribution_engine.dart';

void main() {
  final now = DateTime.utc(2026, 10, 31, 12);

  ViralSignal signal({
    DateTime? observedAt,
    double evidenceConfidence = 90,
    bool rightsCleared = true,
    double momentum = 90,
  }) => ViralSignal(
    topic: 'Original monkey comedy character',
    sourceUrl: 'https://example.com/trend-evidence',
    observedAt: observedAt ?? now.subtract(const Duration(hours: 2)),
    momentum: momentum,
    audienceFit: 90,
    shareability: 95,
    retentionPotential: 90,
    evidenceConfidence: evidenceConfidence,
    competition: 20,
    productionCost: 15,
    rightsCleared: rightsCleared,
  );

  group('scoreViralSignal', () {
    test('ranks fresh, evidenced, rights-cleared ideas highly', () {
      final result = scoreViralSignal(signal(), now: now);
      expect(result.score, greaterThan(80));
      expect(result.blockers, isEmpty);
      expect(result.recommendation, 'أولوية اختبار إنتاجي صغير');
    });

    test('blocks production recommendation when rights are not cleared', () {
      final result = scoreViralSignal(signal(rightsCleared: false), now: now);
      expect(result.blockers, contains('حقوق الصور والصوت والمقاطع لم تُراجع'));
      expect(result.recommendation, 'مراجعة مطلوبة قبل الإنتاج');
    });

    test('reduces stale signal recency and requires recheck', () {
      final result = scoreViralSignal(
        signal(observedAt: now.subtract(const Duration(days: 5))),
        now: now,
      );
      expect(result.blockers, contains('الإشارة أقدم من 72 ساعة؛ أعد التحقق'));
    });

    test('requires evidence confidence', () {
      final result = scoreViralSignal(signal(evidenceConfidence: 20), now: now);
      expect(result.blockers, contains('الأدلة ضعيفة؛ تحقق من الاتجاه بمصدر مستقل'));
    });

    test('rejects invalid metric values and future observations', () {
      expect(
        () => scoreViralSignal(signal(momentum: 101), now: now),
        throwsArgumentError,
      );
      expect(
        () => scoreViralSignal(
          signal(observedAt: now.add(const Duration(minutes: 1))),
          now: now,
        ),
        throwsArgumentError,
      );
    });

    test('ranking is best-first, stable for ties, and immutable', () {
      final ranked = rankViralSignals([signal(momentum: 70), signal()], now: now);
      expect(ranked.first.score, greaterThanOrEqualTo(ranked.last.score));
      expect(() => ranked.add(ranked.first), throwsUnsupportedError);
    });
  });

  group('VirtualCharacterConcept', () {
    test('accepts a complete original character bible', () {
      const character = VirtualCharacterConcept(
        id: 'monkey-001',
        name: 'Koko the Curious',
        role: 'Curious neighborhood inventor',
        visualIdentity: 'Original teal cap, amber vest, round glasses',
        personality: 'Playful, observant, kind, and impulsive',
        recurringHook: 'Every tiny invention causes a funny chain reaction',
        originalityNotes: 'Original design, voice, backstory, and catchphrases',
      );
      expect(() => character.validate(), returnsNormally);
    });

    test('rejects incomplete character concepts', () {
      const character = VirtualCharacterConcept(
        id: 'monkey-001',
        name: '',
        role: 'Comic lead',
        visualIdentity: 'Unique silhouette',
        personality: 'Curious',
        recurringHook: 'Unexpected twist',
        originalityNotes: 'Original concept',
      );
      expect(character.validate, throwsArgumentError);
    });
  });

  test('distribution drafts are platform-specific and require approval', () {
    final drafts = buildDistributionDrafts('A short comedy about a curious monkey');
    expect(drafts.map((draft) => draft.platform).toSet(), {
      'YouTube Shorts',
      'TikTok',
      'Instagram Reels',
      'X',
    });
    expect(drafts.every((draft) => draft.approvalRequired), isTrue);
    expect(() => buildDistributionDrafts('  '), throwsArgumentError);
  });
}
