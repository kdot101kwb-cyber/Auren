import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/social/adaptive_profile_service.dart';
import 'package:auren/services/social/profile_mode_service.dart';

void main() {
  const adaptive = AurenAdaptiveProfileService();

  test('business context proposes Business without changing current mode', () {
    final result = adaptive.suggest(
      currentMode: AurenProfileMode.personal,
      context: AurenProfileContext.business,
      intent: 'ابحث عن عملاء ومنتجات',
    );

    expect(result.mode, AurenProfileMode.business);
    expect(result.confidence, 92);
    expect(result.alternatives, isNotEmpty);
  });

  test('creator context proposes Creator', () {
    final result = adaptive.suggest(
      currentMode: AurenProfileMode.professional,
      context: AurenProfileContext.content,
      intent: 'محتوى وفيديو وجمهور',
    );

    expect(result.mode, AurenProfileMode.creator);
  });

  test('unknown context keeps current mode when there are no signals', () {
    final result = adaptive.suggest(
      currentMode: AurenProfileMode.professional,
      context: AurenProfileContext.unknown,
      intent: 'شيء جديد',
    );

    expect(result.mode, AurenProfileMode.professional);
    expect(result.confidence, 100);
  });

  test('unknown context detects profile signals', () {
    final result = adaptive.suggest(
      currentMode: AurenProfileMode.personal,
      context: AurenProfileContext.unknown,
      profile: AurenProfileModeData.empty(AurenProfileMode.personal).copyWith(
        interests: const ['video', 'content'],
      ),
    );

    expect(result.mode, AurenProfileMode.creator);
    expect(result.confidence, greaterThanOrEqualTo(68));
  });
}
