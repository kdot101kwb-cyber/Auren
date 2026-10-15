/// Resolves accessible presentation preferences into a consistent UI profile.
///
/// This pure policy layer does not alter system accessibility settings. UI
/// components should apply the result and continue honoring platform settings.
class AccessibilityPreferences {
  const AccessibilityPreferences({
    this.textScale = 1.0,
    this.highContrast = false,
    this.reduceMotion = false,
    this.captionsEnabled = true,
    this.simplifiedLayout = false,
    this.largeTouchTargets = false,
  });

  final double textScale;
  final bool highContrast;
  final bool reduceMotion;
  final bool captionsEnabled;
  final bool simplifiedLayout;
  final bool largeTouchTargets;
}

class AccessibilityPresentationProfile {
  const AccessibilityPresentationProfile({
    required this.textScale,
    required this.highContrast,
    required this.reduceMotion,
    required this.captionsEnabled,
    required this.simplifiedLayout,
    required this.minimumTouchTarget,
    required this.animationDurationFactor,
    required this.showDecorativeMotion,
  });

  final double textScale;
  final bool highContrast;
  final bool reduceMotion;
  final bool captionsEnabled;
  final bool simplifiedLayout;
  final double minimumTouchTarget;
  final double animationDurationFactor;
  final bool showDecorativeMotion;
}

class AccessibilityPreferencesResolver {
  const AccessibilityPreferencesResolver();

  AccessibilityPresentationProfile resolve({
    required AccessibilityPreferences preferences,
    bool platformReduceMotion = false,
    bool platformHighContrast = false,
    double platformTextScale = 1.0,
  }) {
    if (!preferences.textScale.isFinite ||
        preferences.textScale < 0.8 ||
        preferences.textScale > 2.0) {
      throw ArgumentError.value(preferences.textScale, 'textScale', 'Must be finite and between 0.8 and 2.0');
    }
    if (!platformTextScale.isFinite ||
        platformTextScale < 0.8 ||
        platformTextScale > 2.0) {
      throw ArgumentError.value(platformTextScale, 'platformTextScale', 'Must be finite and between 0.8 and 2.0');
    }

    final textScale = (preferences.textScale * platformTextScale).clamp(0.8, 2.4).toDouble();
    final reduceMotion = preferences.reduceMotion || platformReduceMotion;
    final highContrast = preferences.highContrast || platformHighContrast;
    return AccessibilityPresentationProfile(
      textScale: textScale,
      highContrast: highContrast,
      reduceMotion: reduceMotion,
      captionsEnabled: preferences.captionsEnabled,
      simplifiedLayout: preferences.simplifiedLayout,
      minimumTouchTarget: preferences.largeTouchTargets ? 56 : 48,
      animationDurationFactor: reduceMotion ? 0 : 1,
      showDecorativeMotion: !reduceMotion,
    );
  }
}
