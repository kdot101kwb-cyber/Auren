import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/social/adaptive_profile_service.dart';
import 'package:auren/services/social/profile_mode_service.dart';

void main() {
  const service = AurenAdaptiveProfileService();

  test('explicit context maps to the expected profile mode', () {
    final result = service.suggest(
      currentMode: AurenProfileMode.personal,
      context: AurenProfileContext.business,
    );

    expect(result.mode, AurenProfileMode.business);
    expect(result.confidence, 92);
  });

  test('Arabic spelling variants are normalized before detection', () {
    final result = service.suggest(
      currentMode: AurenProfileMode.personal,
      intent: 'أرخص خدمة لعملاء وشركة',
    );

    expect(result.mode, AurenProfileMode.business);
    expect(result.confidence, greaterThanOrEqualTo(68));
  });

  test('profile signals can suggest creator mode', () {
    final result = service.suggest(
      currentMode: AurenProfileMode.personal,
      profile: AurenProfileModeData(
        mode: AurenProfileMode.personal,
        headline: 'صانع محتوى',
        bio: 'فيديو وموسيقى للجمهور',
        skills: const [],
        interests: const [],
        links: const [],
        goals: const [],
        languages: const [],
        services: const [],
        achievements: const [],
        discoverable: true,
        showContact: false,
      ),
    );

    expect(result.mode, AurenProfileMode.creator);
    expect(result.alternatives, isNotEmpty);
  });

  test('unknown context keeps current mode when no strong signal exists', () {
    final result = service.suggest(
      currentMode: AurenProfileMode.professional,
      intent: 'hello',
    );

    expect(result.mode, AurenProfileMode.professional);
    expect(result.confidence, 100);
  });
}
