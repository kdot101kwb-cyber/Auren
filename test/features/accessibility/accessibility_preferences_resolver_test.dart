import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/accessibility/domain/accessibility_preferences_resolver.dart';

void main() {
  const resolver = AccessibilityPreferencesResolver();

  test('combines app and platform contrast and motion settings safely', () {
    final profile = resolver.resolve(
      preferences: const AccessibilityPreferences(),
      platformReduceMotion: true,
      platformHighContrast: true,
    );
    expect(profile.reduceMotion, isTrue);
    expect(profile.highContrast, isTrue);
    expect(profile.animationDurationFactor, 0);
    expect(profile.showDecorativeMotion, isFalse);
  });

  test('combines text scales and caps the effective result', () {
    final profile = resolver.resolve(
      preferences: const AccessibilityPreferences(textScale: 1.8),
      platformTextScale: 1.8,
    );
    expect(profile.textScale, 2.4);
  });

  test('respects captions, simplified layout, and large touch targets', () {
    final profile = resolver.resolve(
      preferences: const AccessibilityPreferences(
        captionsEnabled: true,
        simplifiedLayout: true,
        largeTouchTargets: true,
      ),
    );
    expect(profile.captionsEnabled, isTrue);
    expect(profile.simplifiedLayout, isTrue);
    expect(profile.minimumTouchTarget, 56);
  });

  test('caps combined scale and preserves reduced motion at high scale', () { final profile = resolver.resolve(preferences: const AccessibilityPreferences(textScale: 2.0, reduceMotion: true), platformTextScale: 2.0); expect(profile.textScale, 2.4); expect(profile.reduceMotion, isTrue); expect(profile.animationDurationFactor, 0); });

  test('rejects invalid app and platform text scales', () {
    expect(
      () => resolver.resolve(
        preferences: const AccessibilityPreferences(textScale: double.nan),
      ),
      throwsArgumentError,
    );
    expect(
      () => resolver.resolve(
        preferences: const AccessibilityPreferences(),
        platformTextScale: 0.5,
      ),
      throwsArgumentError,
    );
  });
}
